//
//  NINMessagesViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINSessionManager;

@interface NINInitialViewController : UIViewController

/** Reference to the session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

@end
