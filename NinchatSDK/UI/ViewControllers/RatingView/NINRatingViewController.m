//
//  NINRatingViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINRatingViewController.h"

@interface NINRatingViewController ()

@end

@implementation NINRatingViewController

#pragma mark - IBAction handlers

-(IBAction) happyFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Happy face pressed");
}

-(IBAction) neutralFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Neutral face pressed");

}

-(IBAction) sadFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Sad face pressed");

}

-(IBAction) skipButtonPressed:(id)sender {
    NSLog(@"Skip button pressed");
}

@end
