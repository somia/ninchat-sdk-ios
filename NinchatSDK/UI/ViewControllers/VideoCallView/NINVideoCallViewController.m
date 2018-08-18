//
//  NINVideoCallViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINVideoCallViewController.h"

#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AVFoundation/AVFoundation.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>

#import "NINWebRTCClient.h"

@interface NINVideoCallViewController () <NINWebRTCClientDelegate, RTCEAGLVideoViewDelegate>

@property (strong, nonatomic) IBOutlet RTCEAGLVideoView* remoteView;
//@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack* remoteVideoTrack;

@property (assign, nonatomic) CGSize remoteVideoSize;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewBottomConstraint;

@end

@implementation NINVideoCallViewController

#pragma mark - Private methods

- (void)disconnect {
    NSLog(@"NINCHAT: disconnect");
/*
    if (self.client) {
//        if (self.localVideoTrack) [self.localVideoTrack removeRenderer:self.localView];
//        self.localVideoTrack = nil;
//        [self.localView renderFrame:nil];

        if (self.remoteVideoTrack != nil) {
            [self.remoteVideoTrack removeRenderer:self.remoteView];
        }
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];

        [self.client disconnect];
    }
 */
}

-(void) remoteDisconnected {
    NSLog(@"NINCHAT: remoteDisconnected");

    if (self.remoteVideoTrack != nil) {
        [self.remoteVideoTrack removeRenderer:self.remoteView];
    }

    self.remoteVideoTrack = nil;
    [self.remoteView renderFrame:nil];
   // [self videoView:self.localView didChangeVideoSize:self.localVideoSize];
}

-(void) orientationChanged:(NSNotification *)notification{
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

#pragma mark - IBAction handlers

-(IBAction) closeButtonPressed:(UIButton*)button {
    [self disconnect];

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - From NINWebRTCClientDelegate

-(void) webrtcClient:(NINWebRTCClient *)client didGetError:(NSError *)error {
    NSLog(@"NINCHAT: didGetError: %@", error);

    [self disconnect];
}

-(void) webrtcClient:(NINWebRTCClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
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

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self disconnect];
}

-(void) applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    [self.remoteView setDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

@end
