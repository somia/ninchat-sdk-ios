//
//  QueueViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINSessionManager;

/** Displays a waiting view while the user is in a queue. */
@interface NINQueueViewController : UIViewController

/** Reference to the session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

@end
