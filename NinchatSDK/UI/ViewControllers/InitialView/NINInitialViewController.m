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

// Segue id to open queue view
static NSString* const kSegueIdInitialToQueue = @"ninchatsdk.InitialToQueue";

@interface NINInitialViewController ()

@property (nonatomic, strong) IBOutlet UIButton* startChatButton;
@property (nonatomic, strong) IBOutlet UIButton* closeWindowButton;

@end

@implementation NINInitialViewController

#pragma mark - IBAction handlers

-(IBAction) startChatButtonPressed:(UIButton*)button {
    // Select a queue; just pick the first one available
    if (self.sessionManager.queues.count == 0) {
        // No queues? well this simply wont do.
        NSLog(@"** ERROR ** No queues found!");
        return;
    }

    [self performSegueWithIdentifier:kSegueIdInitialToQueue sender:self.sessionManager.queues[0]];
}

-(IBAction) closeWindowButtonPressed:(UIButton*)button {
    [self.sessionManager closeChat];
}

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdInitialToQueue]) {
        NINQueueViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
        vc.queueToJoin = (NINQueue*)sender;
    }
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString* queueButtonText = [NSString stringWithFormat:@"Join %@", self.sessionManager.queues[0].name];
    [self.startChatButton setTitle:queueButtonText forState:UIControlStateNormal];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    self.startChatButton.layer.cornerRadius = self.startChatButton.bounds.size.height / 2;
    self.closeWindowButton.layer.cornerRadius = self.closeWindowButton.bounds.size.height / 2;
    self.closeWindowButton.layer.borderColor = [UIColor colorWithRed:73/255.0 green:172/255.0 blue:253/255.0 alpha:1].CGColor;
    self.closeWindowButton.layer.borderWidth = 1;
}

@end
