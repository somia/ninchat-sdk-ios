//
//  QueueViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINBaseViewController.h"

@class NINSessionManager;

/** Displays a waiting view while the user is in a queue. */
@interface NINQueueViewController : NINBaseViewController

/** ID of the queue to connect to. If nil, does not join a queue. */
@property (nonatomic, strong) NSString* queueIdToJoin;

@end
