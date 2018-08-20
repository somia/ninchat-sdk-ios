//
//  NINVideoCallViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINWebRTCClient;

@interface NINVideoCallViewController : UIViewController

/** WebRTC client for the video call. */
@property (nonatomic, strong) NINWebRTCClient* webrtcClient;

@end
