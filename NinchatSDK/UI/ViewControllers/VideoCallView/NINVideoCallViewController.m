//
//  NINVideoCallViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AVFoundation/AVFoundation.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>

#import "NINVideoCallViewController.h"
#import "NINWebRTCClient.h"
#import "NINUtils.h"
#import "NINSessionManager.h"

@interface NINVideoCallViewController () <NINWebRTCClientDelegate, RTCEAGLVideoViewDelegate>

@property (strong, nonatomic) IBOutlet RTCEAGLVideoView* remoteView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView* localView;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack* remoteVideoTrack;

@property (assign, nonatomic) CGSize remoteVideoSize;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewBottomConstraint;

@end

@implementation NINVideoCallViewController

// For reference, see:
// https://github.com/ISBX/apprtc-ios/blob/master/AppRTC/ARTCVideoChatViewController.m

#pragma mark - Private methods

-(void) disconnect {
    NSLog(@"NINCHAT: disconnect");

    if (self.webrtcClient != nil) {
        // Clean up local video view
        if (self.localVideoTrack != nil) {
            [self.localVideoTrack removeRenderer:self.localView];
        }
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];

        // Clean up remote video view
        if (self.remoteVideoTrack != nil) {
            [self.remoteVideoTrack removeRenderer:self.remoteView];
        }
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];

        // Finally, disconnect the WebRTC client.
        [self.webrtcClient disconnect];
        self.webrtcClient = nil;
    }
}

-(void) listenToWebRTCSignaling {
    __weak typeof(self) weakSelf = self;
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCHangup]) {
            NSLog(@"Got WebRTC hang-up - closing the video call.");

            // Disconnect and leave this view
            [weakSelf disconnect];
            [weakSelf.navigationController popViewControllerAnimated:YES];

            return YES;
        }

        return NO;
    });
}

-(void) orientationChanged:(NSNotification*)notification {
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

-(void) applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

#pragma mark - IBAction handlers

-(IBAction) hangupButtonPressed:(UIButton*)button {
    __weak typeof(self) weakSelf = self;

    [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCHangup payloadDict:@{} completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Failed to send hang-up: %@", error);
        }

        // Disconnect the WebRTC client, remove signaling observer and get rid of this view
        [weakSelf disconnect];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.signalingObserver];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - From NINWebRTCClientDelegate

-(void) webrtcClient:(NINWebRTCClient *)client didGetError:(NSError *)error {
    NSLog(@"NINCHAT: didGetError: %@", error);

    [self disconnect];
}

-(void) webrtcClient:(NINWebRTCClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    NSLog(@"NINCHAT: didReceiveLocalVideoTrack: %@", localVideoTrack);
    //TODO implement me
}

-(void) webrtcClient:(NINWebRTCClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    NSLog(@"NINCHAT: didReceiveRemoteVideoTrack: %@", remoteVideoTrack);

    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteView];
}

#pragma mark - From RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    NSLog(@"NINCHAT: didChangeVideoSize: %@", NSStringFromCGSize(size));
    
    [UIView animateWithDuration:0.4f animations:^{
        CGFloat containerWidth = self.view.frame.size.width;
        CGFloat containerHeight = self.view.frame.size.height;
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        self.remoteVideoSize = size;
        CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
        CGRect videoRect = self.view.bounds;
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

        [self.remoteViewTopConstraint setConstant:(containerHeight / 2 - videoFrame.size.height / 2)];
        [self.remoteViewBottomConstraint setConstant:(containerHeight / 2 - videoFrame.size.height / 2)];
        [self.remoteViewLeftConstraint setConstant:(containerWidth / 2 - videoFrame.size.width / 2)];
        [self.remoteViewRightConstraint setConstant:(containerWidth / 2 - videoFrame.size.width / 2)];

        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSCAssert(self.webrtcClient != nil, @"Must have webrtc client");
    NSCAssert(self.sessionManager != nil, @"Must have session manager");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    if (self.offerSDP != nil) {
        NSLog(@"Video Call view: Starting WebRTC client..");
        self.webrtcClient.delegate = self;
        [self.webrtcClient startWithSDP:self.offerSDP];
        self.offerSDP = nil;

        // Start listening to WebRTC signaling messages from the chat session manager
        [self listenToWebRTCSignaling];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    [self disconnect];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    self.remoteView.delegate = self;
//    self.localView.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
