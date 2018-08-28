//
//  NINVideoCallViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINSessionManager;
@class NINWebRTCClient;

@interface NINVideoCallViewController : UIViewController

/** Reference to the session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** WebRTC client for the video call. */
@property (nonatomic, strong) NINWebRTCClient* webrtcClient;

/** Dictionary representing SDP data for initializing the WebRTC client for answering a call. */
@property (nonatomic, strong) NSDictionary* offerSDP;

@end
