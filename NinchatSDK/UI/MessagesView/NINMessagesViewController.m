//
//  NINMessagesViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#include <stdlib.h>

#import "NINMessagesViewController.h"

// Segue to open video call view
static NSString* const kSegueIdMessagesToVideoCall = @"MessagesToVideoCall";

@interface NINMessagesViewController ()

@property IBOutlet UILabel* testLabel;

@end

@implementation NINMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.testLabel.text = @"NINCHAT SDK SAYS: Hi!";
}

-(IBAction) pushButtonPressed:(UIButton*)button {
    self.testLabel.text = [NSString stringWithFormat:@"Here's a random number: %d", arc4random_uniform(74)];
}

-(IBAction) videoCallButtonPressed:(UIButton*)button {
    [self performSegueWithIdentifier:kSegueIdMessagesToVideoCall sender:self];
}

@end
