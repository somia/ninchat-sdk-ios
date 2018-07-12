//
//  QueueViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINQueueViewController.h"
#import "NINSessionManager.h"

@interface NINQueueViewController ()

@end

@implementation NINQueueViewController

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSAssert(self.queueId != nil, @"queueId not defined");

    //TODO listen to Channel Joined -notifications! or even better, add channelJoined -block to the call below.

    // Connect to the queue
    [self.sessionManager joinQueueWithId:self.queueId completion:^(NSError* error) {
        NSLog(@"Queue join completed, error: %@", error);
    }];
}

@end
