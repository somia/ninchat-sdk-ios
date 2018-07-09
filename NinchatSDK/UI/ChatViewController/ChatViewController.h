//
//  ChatViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "MXRMessengerViewController.h"

@class SessionManager;

/**
 * Provides a chat view with message input and chat 'bubbles'.
 */
@interface ChatViewController : MXRMessengerViewController

/** Reference to the session manager instance. */
@property (nonatomic, strong) SessionManager* sessionManager;

@end
