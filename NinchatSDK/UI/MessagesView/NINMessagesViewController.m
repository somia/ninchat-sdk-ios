//
//  NINMessagesViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Ninchat. All rights reserved.
//

#import "NINMessagesViewController.h"

@interface NINMessagesViewController ()

@property IBOutlet UILabel* testLabel;

@end

@implementation NINMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.testLabel.text = @"NINCHAT SDK SAYS: Hi!";
}

@end
