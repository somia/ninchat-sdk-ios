//
//  NINWebRTCClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AVFoundation;

@import Libjingle;

#import "RTCSessionDescription+Dictionary.h"
#import "RTCICECandidate+Dictionary.h"

#import "NINSessionManager.h"
#import "NINWebRTCClient.h"
#import "NINWebRTCServerInfo.h"
#import "NINUtils.h"
#import "NINToast.h"

// See the WebRTC signaling diagram:
// https://mdn.mozillademos.org/files/12363/WebRTC%20-%20Signaling%20Diagram.svg

@interface NINWebRTCClient () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

// Session manager, used for signaling
@property (nonatomic, weak) NINSessionManager* sessionManager;

// Operation mode; caller or callee.
@property (nonatomic, assign) NINWebRTCClientOperatingMode operatingMode;

// Factory for creating our RTC peer connections
@property (nonatomic, strong) RTCPeerConnectionFactory* peerConnectionFactory;

// List of our ICE servers (STUN, TURN)
@property (nonatomic, strong) NSMutableArray<RTCICEServer*>* iceServers;

// Current RTC peer connection if any
@property (nonatomic, strong) RTCPeerConnection* peerConnection;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

// Default local audio track
@property(nonatomic, strong) RTCAudioTrack* defaultLocalAudioTrack;

// Default local video track
@property(nonatomic, strong) RTCVideoTrack* defaultLocalVideoTrack;

// Whether to enable the speaker
//@property (nonatomic, assign) BOOL isSpeakerEnabled;

@end

@implementation NINWebRTCClient

#pragma mark - Private Methods

-(RTCMediaConstraints*) defaultOfferConstraints {
    NSArray* mandatoryConstraints = @[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]];
    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
}

-(RTCVideoTrack*) createLocalVideoTrack {
    RTCVideoTrack *localVideoTrack = nil;

#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    // Camera capture only works on the device, not the simulator
    NSString* cameraID = nil;
    for (AVCaptureDevice* captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSCAssert(cameraID != nil, @"Unable to get the front camera id");

    RTCVideoCapturer* capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints* mediaConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    RTCVideoSource* videoSource = [self.peerConnectionFactory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [self.peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}

-(RTCMediaStream*) createLocalMediaStream {
    //TODO what are these labels
    RTCMediaStream* localStream = [self.peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];

    RTCVideoTrack* localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack != nil) {
        [localStream addVideoTrack:localVideoTrack];
        [self.delegate webrtcClient:self didReceiveLocalVideoTrack:localVideoTrack];
    }

    //TODO what are these labels
    [localStream addAudioTrack:[self.peerConnectionFactory audioTrackWithID:@"ARDAMSa0"]];

    //TODO
//    if (_isSpeakerEnabled) [self enableSpeaker];
    return localStream;
}

#pragma mark - Public Methods

-(void) disconnect {
    [self.sessionManager.ninchatSession sdklog:@"WebRTC Client disconnecting."];

    if (self.peerConnection != nil) {
        [self.peerConnection close];
        self.peerConnection = nil;
    }

    self.defaultLocalAudioTrack = nil;
    self.defaultLocalVideoTrack = nil;
    self.peerConnectionFactory = nil;
    self.sessionManager = nil;
    self.iceServers = nil;
    
    [NSNotificationCenter.defaultCenter removeObserver:self.signalingObserver];
    self.signalingObserver = nil;

    [self.sessionManager.ninchatSession sdklog:@"WebRTC Client disconnected."];
}

-(void) startWithSDP:(NSDictionary*)sdp {
    NSCAssert(self.peerConnectionFactory != nil, @"Invalid state - client was disconnected?");
    NSCAssert(self.sessionManager != nil, @"Invalid state - client was disconnected?");
    NSCAssert(self.signalingObserver == nil, @"Cannot have active observer already");

//    NSLog(@"WebRTC: Starting with SDP: %@", sdp);

    __weak typeof(self) weakSelf = self;

    // Start listening to WebRTC signaling messages from the chat session manager
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        NSLog(@"WebRTC: got signaling message: %@", note.userInfo[@"messageType"]);

        NSDictionary* payload = note.userInfo[@"payload"];
        NSLog(@"WebRTC: Signaling message payload: %@", payload);

        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCIceCandidate]) {
            RTCICECandidate* candidate = [RTCICECandidate fromDictionary:payload[@"sdp"]];
            [weakSelf.peerConnection addICECandidate:candidate];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCAnswer]) {
            RTCSessionDescription* description = [RTCSessionDescription fromDictionary:payload[@"sdp"]];
            NSCAssert(description != nil, @"Session description cannot be null");
            NSLog(@"Setting local remote description with SDP: %@", description);
            [weakSelf.peerConnection setRemoteDescriptionWithDelegate:weakSelf sessionDescription:description];
        }

        return NO;
    });

    NSArray* optionalConstraints = @[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];

    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:self.iceServers constraints:constraints delegate:self];
    [self.peerConnection addStream:[self createLocalMediaStream]];

    if (self.operatingMode == NINWebRTCClientOperatingModeCaller) {
        // We are the 'caller', ie. the connection initiator; create a connection offer
        NSLog(@"WebRTC: making a call.");
        [self.peerConnection createOfferWithDelegate:self constraints:[self defaultOfferConstraints]];
    } else {
        // We are the 'callee', ie. we are answering.
        NSCAssert(sdp != nil, @"Must have Offer SDP data");
        NSLog(@"WebRTC: answering call with SDP: %@", sdp);
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:[RTCSessionDescription fromDictionary:sdp]];
    }
}

-(void) muteLocalAudio {
    RTCMediaStream* localStream = self.peerConnection.localStreams[0];
    self.defaultLocalAudioTrack = localStream.audioTracks[0];
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
}

-(void) unmuteLocalAudio {
    RTCMediaStream* localStream = self.peerConnection.localStreams[0];
    [localStream addAudioTrack:self.defaultLocalAudioTrack];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
//    if (self.isSpeakerEnabled) {
//        [self enableSpeaker];
//    }
}

-(void) disableLocalVideo {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    // Camera capture only works on the device, not the simulator
    RTCMediaStream *localStream = self.peerConnection.localStreams[0];
    self.defaultLocalVideoTrack = localStream.videoTracks[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
#endif
}
-(void) enableLocalVideo {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    // Camera capture only works on the device, not the simulator
    RTCMediaStream* localStream = self.peerConnection.localStreams[0];
    [localStream addVideoTrack:self.defaultLocalVideoTrack];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
#endif
}

//-(void) enableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
//    self.isSpeakerEnabled = YES;
//}
//
//-(void) disableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
//    self.isSpeakerEnabled = NO;
//}

#pragma mark - From RTCPeerConnectionDelegate

-(void) peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream {
    NSLog(@"WebRTC: Received %lu video tracks and %lu audio tracks", (unsigned long)stream.videoTracks.count, (unsigned long)stream.audioTracks.count);

    runOnMainThread(^{
        if (stream.videoTracks.count > 0) {
            [self.delegate webrtcClient:self didReceiveRemoteVideoTrack:stream.videoTracks[0]];
            //            if (_isSpeakerEnabled) [self enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.
        }
    });
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"WebRTC: opened data channel: %@", dataChannel);
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate {
    NSLog(@"WebRTC: got ICE candidate: %@", candidate);

    runOnMainThread(^{
        [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCIceCandidate payloadDict:@{@"candidate": candidate.dictionary} completion:^(NSError* error) {
            if (error != nil) {
                NSLog(@"WebRTC: Failed to send ICE candidate: %@", error);
            }
        }];
    });
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState {
    NSLog(@"WebRTC: ICE connection state changed: %d", newState);
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState {
    NSLog(@"WebRTC: ICE gathering state changed: %d", newState);
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream {
    NSLog(@"WebRTC: removed stream: %@", stream);
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged {
    NSLog(@"WebRTC: Signaling state changed: %d", stateChanged);
}

-(void) peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    //TODO see:
    // https://stackoverflow.com/questions/31165316/webrtc-renegotiate-the-peer-connection-to-switch-streams
    // https://stackoverflow.com/questions/29511602/how-to-exchange-streams-from-two-peerconnections-with-offer-answer/29530757#29530757
    NSLog(@"WebRTC: **WARNING** renegotiation needed - unimplemented!");
}

#pragma mark - From RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    NSLog(@"WebRTC: didCreateSessionDescription: %@", sdp);

    runOnMainThread(^{
        if (error != nil) {
            NSLog(@"WebRTC: got create session error: %@", error);
            [self disconnect];
            [self.delegate webrtcClient:self didGetError:error];
            return;
        }

        NSLog(@"Setting local session description with SDP: %@", sdp);
        [self.peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];

        // Decide what type of signaling message to send based on the SDP type
        NSDictionary* typeMap = @{@"offer": kNINMessageTypeWebRTCOffer, @"answer": kNINMessageTypeWebRTCAnswer};
        NSString* messageType = typeMap[sdp.type];
        if (messageType == nil) {
            NSLog(@"WebRTC: Unknown SDP type: %@", sdp.type);
            return;
        }

        NSLog(@"Sending signaling message with type %@ and payload %@", messageType, @{@"sdp": sdp.dictionary});

        // Send signaling message about the offer/answer
        [self.sessionManager sendMessageWithMessageType:messageType payloadDict:@{@"sdp": sdp.dictionary} completion:^(NSError* error) {
            if (error != nil) {
                NSLog(@"WebRTC: Message send error: %@", error);
                [NINToast showWithErrorMessage:@"Failed to send RTC signaling message" callback:nil];
            }
        }];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    NSLog(@"WebRTC: didSetSessionDescriptionWithError: %@", error);

    runOnMainThread(^{
        if (error != nil) {
            NSLog(@"WebRTC: got set session error: %@", error);
            [self.delegate webrtcClient:self didGetError:error];
            [self disconnect];
            return;
        }

        if ((self.operatingMode == NINWebRTCClientOperatingModeCallee) && (self.peerConnection.localDescription == nil)) {
            NSLog(@"WebRTC: Creating answer");
            RTCMediaConstraints* constraints = [self defaultOfferConstraints];
            [self.peerConnection createAnswerWithDelegate:self constraints:constraints];
        }
    });
}

#pragma mark - Initializers

+(instancetype) clientWithSessionManager:(NINSessionManager*)sessionManager operatingMode:(NINWebRTCClientOperatingMode)operatingMode stunServers:(NSArray<NINWebRTCServerInfo*>*)stunServers turnServers:(NSArray<NINWebRTCServerInfo*>*)turnServers {

    [sessionManager.ninchatSession sdklog:@"Creating new NINWebRTCClient in the %@ mode", (operatingMode == NINWebRTCClientOperatingModeCaller) ? @"CALLER" : @"CALLEE"];

    NINWebRTCClient* client = [NINWebRTCClient new];
    client.sessionManager = sessionManager;
    client.operatingMode = operatingMode;

    client.peerConnectionFactory = [RTCPeerConnectionFactory new];
    client.iceServers = [NSMutableArray arrayWithCapacity:(stunServers.count + turnServers.count)];

    for (NINWebRTCServerInfo* serverInfo in stunServers) {
        [client.iceServers addObject:serverInfo.iceServer];
    }

    for (NINWebRTCServerInfo* serverInfo in turnServers) {
        [client.iceServers addObject:serverInfo.iceServer];
    }

    return client;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
