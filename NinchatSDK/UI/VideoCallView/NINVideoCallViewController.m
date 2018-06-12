//
//  NINVideoCallViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINVideoCallViewController.h"

//#import "ARDAppClient.h"
#import <AppRTC/ARDAppClient.h>

//@import WebRTC;

// WebRTC server address
static NSString* const kWebRTCServerAddress = @"https://apprtc.appspot.com"; //TODO

@interface NINVideoCallViewController () <ARDAppClientDelegate>

//@property (nonatomic, strong) RTCPeerConnectionFactory* connFactory;
@property (strong, nonatomic) ARDAppClient* client;

@end

@implementation NINVideoCallViewController

#pragma mark - Private methods

- (void)disconnect {
    if (self.client) {
//        if (self.localVideoTrack) [self.localVideoTrack removeRenderer:self.localView];
//        if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
//        self.localVideoTrack = nil;
//        [self.localView renderFrame:nil];
//        self.remoteVideoTrack = nil;
//        [self.remoteView renderFrame:nil];
        [self.client disconnect];
    }
}

- (void)remoteDisconnected {
//    if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
//    self.remoteVideoTrack = nil;
//    [self.remoteView renderFrame:nil];
//    [self videoView:self.localView didChangeVideoSize:self.localVideoSize];

}

#pragma mark - From ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack*)localVideoTrack {
    NSLog(@"WebRTC: didReceiveLocalVideoTrack: %@", localVideoTrack);

//    if (self.localVideoTrack) {
//        [self.localVideoTrack removeRenderer:self.localView];
//        self.localVideoTrack = nil;
//        [self.localView renderFrame:nil];
//    }
//    self.localVideoTrack = localVideoTrack;
//    [self.localVideoTrack addRenderer:self.localView];
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack*)remoteVideoTrack {
    NSLog(@"WebRTC: didReceiveRemoteVideoTrack: %@", remoteVideoTrack);
//    self.remoteVideoTrack = remoteVideoTrack;
//    [self.remoteVideoTrack addRenderer:self.remoteView];
//
//    [UIView animateWithDuration:0.4f animations:^{
//        //Instead of using 0.4 of screen size, we re-calculate the local view and keep our aspect ratio
//        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//        CGRect videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width/4.0f, self.view.frame.size.height/4.0f);
//        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
//            videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.height/4.0f, self.view.frame.size.width/4.0f);
//        }
//        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(_localView.frame.size, videoRect);
//
//        [self.localViewWidthConstraint setConstant:videoFrame.size.width];
//        [self.localViewHeightConstraint setConstant:videoFrame.size.height];
//
//
//        [self.localViewBottomConstraint setConstant:28.0f];
//        [self.localViewRightConstraint setConstant:28.0f];
//        [self.footerViewBottomConstraint setConstant:-80.0f];
//        [self.view layoutIfNeeded];
//    }];
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    NSLog(@"WebRTC: didError: %@", error);

//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
//                                                        message:[NSString stringWithFormat:@"%@", error]
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//    [alertView show];
    [self disconnect];
}

#pragma mark - Lifecycle etc.

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Set up WebRTC
   // RTCInitializeSSL();
  //  self.connFactory = [RTCPeerConnectionFactory new];

    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    [self.client setServerHostUrl:kWebRTCServerAddress];
    [self.client connectToRoomWithId:@"NinchatTest" options:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

   // RTCCleanupSSL();
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

@end
