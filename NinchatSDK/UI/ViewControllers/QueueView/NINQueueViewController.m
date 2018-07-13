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

    NSAssert(self.queueId != nil, @"queueId not defined");

    //TODO listen to Channel Joined -notifications! or even better, add channelJoined -block to the call below.

    // Connect to the queue
    [self.sessionManager joinQueueWithId:self.queueId completion:^(NSError* error) {
        NSLog(@"Queue join completed, error: %@", error);
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        NINChatViewController* vc = [NINChatViewController new];
        vc.sessionManager = self.sessionManager;
        [self.navigationController pushViewController:vc animated:YES];

    }];

    // Listen to channel closed -events
    fetchNotification(kChannelClosedNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Channel closed - showing rating view.");

        // First pop the chat view
        [self.navigationController popViewControllerAnimated:YES];

        // Show the rating view
        [self performSegueWithIdentifier:kSegueIdQueueToRating sender:nil];
        
        return YES;
    });
}

@end
