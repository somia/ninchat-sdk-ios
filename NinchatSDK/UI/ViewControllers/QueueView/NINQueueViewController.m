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
#import "NINQueue.h"

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
}

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //TODO better handling here; prevent back gesture from chat view?

    NINQueue* queue = self.queueToJoin;

    if (queue == nil) {
        // Nothing to do; this is the case after we have popped the chat controller
        return;
    }

    self.queueToJoin = nil;

    // Connect to the queue
    [self.sessionManager joinQueueWithId:queue.queueId completion:^(NSError* error) {
        NSLog(@"Queue join completed, error: %@", error);
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        [self performSegueWithIdentifier:kSegueIdQueueToChat sender:nil];
    }];
}

@end
