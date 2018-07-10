//
//  NINVideoCallViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINVideoCallViewController.h"

#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AppRTC/ARDAppClient.h>
#import <AVFoundation/AVFoundation.h>

// WebRTC server address
static NSString* const kWebRTCServerAddress = @"https://appr.tc"; //TODO

@interface NINVideoCallViewController () <ARDAppClientDelegate, RTCEAGLVideoViewDelegate>

//@property (nonatomic, strong) RTCPeerConnectionFactory* connFactory;
@property (strong, nonatomic) ARDAppClient* client;

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

#pragma mark - From ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    NSLog(@"NINCHAT: didChangeState: %ld", (long)state);

    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"NINCHAT: Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"NINCHAT: Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"NINCHAT: Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack*)localVideoTrack {
    NSLog(@"NINCHAT: didReceiveLocalVideoTrack: %@", localVideoTrack);

//    if (self.localVideoTrack) {
//        [self.localVideoTrack removeRenderer:self.localView];
//        self.localVideoTrack = nil;
//        [self.localView renderFrame:nil];
//    }
//    self.localVideoTrack = localVideoTrack;
//    [self.localVideoTrack addRenderer:self.localView];
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack*)remoteVideoTrack {
    NSLog(@"NINCHAT: didReceiveRemoteVideoTrack: %@", remoteVideoTrack);
    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteView];

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
    NSLog(@"NINCHAT: didError: %@", error);

//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
//                                                        message:[NSString stringWithFormat:@"%@", error]
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//    [alertView show];
    [self disconnect];
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

//    [UIView animateWithDuration:0.4f animations:^{
//        CGFloat containerWidth = self.view.frame.size.width;
//        CGFloat containerHeight = self.view.frame.size.height;
//        CGSize defaultAspectRatio = CGSizeMake(4, 3);
//        if (videoView == self.localView) {
//            //Resize the Local View depending if it is full screen or thumbnail
//            self.localVideoSize = size;
//            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
//            CGRect videoRect = self.view.bounds;
//            if (self.remoteVideoTrack) {
//                videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width/4.0f, self.view.frame.size.height/4.0f);
//                if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
//                    videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.height/4.0f, self.view.frame.size.width/4.0f);
//                }
//            }
//            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);
//
//            //Resize the localView accordingly
//            [self.localViewWidthConstraint setConstant:videoFrame.size.width];
//            [self.localViewHeightConstraint setConstant:videoFrame.size.height];
//            if (self.remoteVideoTrack) {
//                [self.localViewBottomConstraint setConstant:28.0f]; //bottom right corner
//                [self.localViewRightConstraint setConstant:28.0f];
//            } else {
//                [self.localViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f]; //center
//                [self.localViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
//            }
//        } else if (videoView == self.remoteView) {
//            //Resize Remote View
//            self.remoteVideoSize = size;
//            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
//            CGRect videoRect = self.view.bounds;
//            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);
//            if (self.isZoom) {
//                //Set Aspect Fill
//                CGFloat scale = MAX(containerWidth/videoFrame.size.width, containerHeight/videoFrame.size.height);
//                videoFrame.size.width *= scale;
//                videoFrame.size.height *= scale;
//            }
//            [self.remoteViewTopConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
//            [self.remoteViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
//            [self.remoteViewLeftConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
//            [self.remoteViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
//
//        }
//        [self.view layoutIfNeeded];
//    }];

}

#pragma mark - Lifecycle etc.

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}

-(void) applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

-(void) viewWillAppear:(BOOL)animated {
    NSLog(@"NINCHAT: viewWillAppear");

    [super viewWillAppear:animated];

    NSLog(@"Connecting to room '%@' of server '%@'..", self.roomName, kWebRTCServerAddress);

    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    [self.client setServerHostUrl:kWebRTCServerAddress];
    [self.client connectToRoomWithId:self.roomName options:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

   // RTCCleanupSSL();
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.remoteView setDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

@end
