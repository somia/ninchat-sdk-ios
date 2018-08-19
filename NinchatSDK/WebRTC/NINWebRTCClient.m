//
//  NINWebRTCClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <libjingle_peerconnection/RTCPeerConnection.h>
#import <libjingle_peerconnection/RTCPeerConnectionDelegate.h>
#import <libjingle_peerconnection/RTCPeerConnectionFactory.h>
#import <libjingle_peerconnection/RTCSessionDescriptionDelegate.h>
#import <libjingle_peerconnection/RTCICEServer.h>
#import <libjingle_peerconnection/RTCMediaConstraints.h>
#import <libjingle_peerconnection/RTCMediaStream.h>
#import <libjingle_peerconnection/RTCPair.h>
#import <libjingle_peerconnection/RTCSessionDescription.h>
#import <libjingle_peerconnection/RTCICECandidate.h>

#import "NINSessionManager.h"
#import "NINWebRTCClient.h"
#import "NINWebRTCServerInfo.h"
#import "NINUtils.h"

// See the WebRTC signaling diagram:
// https://mdn.mozillademos.org/files/12363/WebRTC%20-%20Signaling%20Diagram.svg

@interface NINWebRTCClient () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

// Session manager, used for signaling
@property (nonatomic, strong) NINSessionManager* sessionManager;

// Factory for creating our RTC peer connections
@property (nonatomic, strong) RTCPeerConnectionFactory* peerConnectionFactory;

// List of our ICE servers (STUN, TURN)
@property (nonatomic, strong) NSMutableArray<RTCICEServer*>* iceServers;

// Current RTC peer connection if any
@property (nonatomic, strong) RTCPeerConnection* peerConnection;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id signalingObserver;

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
    NSAssert(cameraID != nil, @"Unable to get the front camera id");

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

-(void) disconnect {
    [self.peerConnection close];
    self.peerConnection = nil;
    self.sessionManager = nil;

    [NSNotificationCenter.defaultCenter removeObserver:self.signalingObserver];
}

#pragma mark - Public Methods

-(void) start {
    // Start listening to WebRTC signaling messages from the chat session manager
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Got WebRTC signaling message: %@", note);

        NSDictionary* payload = note.userInfo[@"payload"];
        NSLog(@"Signaling message payload: %@", payload);

        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCIceCandidate]) {
            NSLog(@"Adding an ICE candidate");

            RTCICECandidate* candidate = [[RTCICECandidate alloc] initWithMid:payload[@"id"] index:[payload[@"label"] integerValue] sdp:payload[@"candidate"]];
            NSLog(@"candidate: %@", candidate);
            [self.peerConnection addICECandidate:candidate];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCAnswer]) {
            NSLog(@"Setting remote session description");

            RTCSessionDescription* description = [[RTCSessionDescription alloc] initWithType:@"answer" sdp:payload[@"sdp"]];
            NSLog(@"description: %@", description);
            [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:description];
        }

        return false;
    });

    NSArray* optionalConstraints = @[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];

    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:self.iceServers constraints:constraints delegate:self];
    RTCMediaStream* localStream = [self createLocalMediaStream];
    [self.peerConnection addStream:localStream];

    // We are the 'caller'; create a connection offer
    [self.peerConnection createOfferWithDelegate:self constraints:[self defaultOfferConstraints]];
//    if (_isInitiator) {
//        [self sendOffer];
//    } else {
//        [self waitForAnswer];
//    }
}

#pragma mark - From RTCPeerConnectionDelegate

-(void) peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream {
    NSLog(@"WebRTC: Received %lu video tracks and %lu audio tracks", stream.videoTracks.count, stream.audioTracks.count);

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

    //TODO do we need all of these or just "candidate": key ?
    NSDictionary* candidateDict = @{@"type": @"candidate", @"label": @(candidate.sdpMLineIndex), @"id": candidate.sdpMid, @"candidate": candidate.sdp};
    [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCIceCandidate payloadDict:@{@"candidate": candidateDict} completion:^(NSError* error) {
        NSLog(@"WebRTC Message send: %@", error);
    }];
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
    //TODO how to do this
    NSLog(@"WebRTC: **WARNING** renegotiation needed - unimplemented!");
}

#pragma mark - From RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    NSLog(@"didCreateSessionDescription: %@", sdp);

    runOnMainThread(^{
        if (error != nil) {
            NSLog(@"WebRTC: got create session error: %@", error);
            [self disconnect];
            [self.delegate webrtcClient:self didGetError:error];
            return;
        }

        [self.peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];

        NSLog(@"WebRTC: SDP type: %@", sdp.type);

        if ([sdp.type isEqualToString:@"offer"]) {
            // Send signaling message about the offer
            NSLog(@"Sending SDP description: %@", sdp.description);
            
            [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCOffer payloadDict:@{@"sdp": sdp.description} completion:^(NSError* error) {
                NSLog(@"WebRTC Message send: %@", error);
            }];
        } else {
            NSLog(@"Unknown SDP type!");
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    NSLog(@"didSetSessionDescriptionWithError: %@", error);

    runOnMainThread(^{
        if (error != nil) {
            NSLog(@"WebRTC: got set session error: %@", error);
            [self disconnect];
            [self.delegate webrtcClient:self didGetError:error];
            return;
        }
    });
}

#pragma mark - Initializers

+(instancetype) clientWithSessionManager:(NINSessionManager*)sessionManager stunServers:(NSArray<NINWebRTCServerInfo*>*)stunServers turnServers:(NSArray<NINWebRTCServerInfo*>*)turnServers {
    NINWebRTCClient* client = [NINWebRTCClient new];
    client.sessionManager = sessionManager;

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

@end
