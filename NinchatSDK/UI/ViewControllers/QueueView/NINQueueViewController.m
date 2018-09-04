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
#import "NINChatViewController.h"
//#import "NINRatingViewController.h"
//TODO remove here
//#import "NINVideoCallViewController.h"

static NSString* const kSegueIdQueueToChat = @"ninchatsdk.segue.QueueToChat";

@interface NINQueueViewController ()

@end

@implementation NINQueueViewController

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdQueueToChat]) {
        NINChatViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
    }

    /*
    if ([segue.identifier isEqualToString:kSegueIdQueueToRating]) {
        NINRatingViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
    } else if ([segue.identifier isEqualToString:kSegueIdChatToVideoCall]) {
        NINVideoCallViewController* vc = segue.destinationViewController;
        vc.webrtcClient = sender;
    }*/
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

    // Connect to the queue
    [self.sessionManager joinQueueWithId:queueId completion:^(NSError* error) {
        NSLog(@"Queue join completed, error: %@", error);
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        [self performSegueWithIdentifier:kSegueIdQueueToChat sender:nil];
    }];
}

@end
