//
//  NINRatingViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINRatingViewController.h"
#import "NINSessionManager.h"

@interface NINRatingViewController ()

@end

@implementation NINRatingViewController

#pragma mark - IBAction handlers

-(IBAction) happyFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Happy face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingHappy)];
}

-(IBAction) neutralFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Neutral face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingNeutral)];
}

-(IBAction) sadFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Sad face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingSad)];
}

-(IBAction) skipButtonPressed:(id)sender {
    NSLog(@"Skip button pressed");

    [self.sessionManager finishChat:nil];
}

@end
