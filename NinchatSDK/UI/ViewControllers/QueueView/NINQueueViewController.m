//
//  QueueViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINQueueViewController.h"
#import "NINSessionManager.h"
#import "NINChatViewController.h"
#import "NINUtils.h"
#import "NINRatingViewController.h"

static NSString* const kSegueIdQueueToRating = @"ninchatsdk.segue.QueueToRating";

@interface NINQueueViewController ()

@end

@implementation NINQueueViewController

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdQueueToRating]) {
        NINRatingViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
    }
}

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString* queueId = self.queueIdToJoin;

    if (queueId == nil) {
        // Nothing to do; this is the case after we have popped the chat controller
        return;
    }

    self.queueIdToJoin = nil;

    __weak typeof(self) weakSelf = self;

    // Connect to the queue
    [self.sessionManager joinQueueWithId:queueId completion:^(NSError* error) {
        NSLog(@"Queue join completed, error: %@", error);
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        NINChatViewController* vc = [NINChatViewController new];
        vc.sessionManager = weakSelf.sessionManager;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    }];

    // Listen to channel closed -events
    fetchNotification(kChannelClosedNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Channel closed - showing rating view.");

        // First pop the chat view
        [weakSelf.navigationController popViewControllerAnimated:YES];

        // Show the rating view
        [weakSelf performSegueWithIdentifier:kSegueIdQueueToRating sender:nil];
        
        return YES;
    });
}

@end
