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
#import "ChatViewController.h"

// Segue to open video call view
static NSString* const kSegueIdMessagesToVideoCall = @"MessagesToVideoCall";

@interface NINInitialViewController ()

@property IBOutlet UILabel* testLabel;

@end

@implementation NINInitialViewController

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Start the chat state machine
//    BOOL ok = [self.chat start];
//    if (!ok) {
//        NSLog(@"NINChat.start() failed!");
//    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    self.testLabel.text = @"NINCHAT SDK SAYS: Hi!";

    // Hide navigation bar
    [self.navigationController setNavigationBarHidden:YES];
}

//TODO remove me
-(IBAction) pushButtonPressed:(UIButton*)button {
    self.testLabel.text = [NSString stringWithFormat:@"Here's a random number: %d", arc4random_uniform(74)];
}

-(IBAction) chatTestButtonPressed:(UIButton*)button {
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
}

-(IBAction) videoCallButtonPressed:(UIButton*)button {
    [self performSegueWithIdentifier:kSegueIdMessagesToVideoCall sender:self];
}

#pragma mark - From UIViewController

@end
