//
//  NINMessagesViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#include <stdlib.h>

#import "NINInitialViewController.h"
#import "NINSessionManager.h"
#import "NINQueue.h"
#import "NINQueueViewController.h"

// Segue to open video call view
//static NSString* const kSegueIdMessagesToVideoCall = @"MessagesToVideoCall";

// Segue id to open queue view
static NSString* const kSegueIdInitialToQueue = @"ninchatsdk.InitialToQueue";

@interface NINInitialViewController ()

@property (nonatomic, strong) IBOutlet UIButton* startChatButton;

@end

@implementation NINInitialViewController

#pragma mark - IBAction handlers


-(IBAction) startChatButtonPressed:(UIButton*)button {
    /*
    NSLog(@"Starting a new test chat..");

    NSString* channelId = @"5npnrkp1009m"; // valid value = 5npnrkp1009m

    //TODO call join_channel and show messages view controller
    [self.sessionManager joinChannelWithId:channelId completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Failed to join channel '%@': %@", channelId, error);
        } else {
            NSLog(@"Channel joined.");

            ChatViewController* vc = [ChatViewController new];
            vc.sessionManager = self.sessionManager;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }];
     */

    // Select a queue; just pick the first one available
    if (self.sessionManager.queues.count == 0) {
        // No queues? well this wont do.
        NSLog(@"** ERROR ** No queues found!");
        return;
    }
    NSString* queueId = self.sessionManager.queues[0].queueId;

    [self performSegueWithIdentifier:kSegueIdInitialToQueue sender:queueId];
}

//-(IBAction) videoCallButtonPressed:(UIButton*)button {
//    [self performSegueWithIdentifier:kSegueIdMessagesToVideoCall sender:self];
//}

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdInitialToQueue]) {
        NINQueueViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
        vc.queueIdToJoin = (NSString*)sender;
    }
}

#pragma mark - Lifecycle etc.

-(void) viewDidLayoutSubviews {
    CGFloat height = self.startChatButton.bounds.size.height;
    self.startChatButton.layer.cornerRadius = height / 2;
}

#pragma mark - From UIViewController

@end
