//
//  ChatViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "MXRMessengerViewController.h"

@class NINSessionManager;

/**
 * Provides a chat view with message input and chat 'bubbles'.
 */
@interface NINChatViewController : MXRMessengerViewController

/** Reference to the session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

@end
