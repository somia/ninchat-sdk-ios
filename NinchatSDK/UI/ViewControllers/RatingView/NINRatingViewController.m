//
//  NINRatingViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINRatingViewController.h"
#import "NINSessionManager.h"
#import "UITextView+Ninchat.h"
#import "NINUtils.h"


// UI strings
static NSString* const kTitleText = @"How was our customer service?";
static NSString* const kSkipText = @"Skip";

@interface NINRatingViewController ()

@property (nonatomic, strong) IBOutlet UITextView* titleTextView;
@property (nonatomic, strong) IBOutlet UIButton* skipButton;

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

#pragma mark - From UIViewController

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Lifecycle, etc

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        // Presenting a view controller will trigger a re-evaluation of
        // supportedInterfaceOrientations: and thus will force this view controller into portrait
        static dispatch_once_t presentVcOnceToken;
        dispatch_once(&presentVcOnceToken, ^{
            runOnMainThreadWithDelay(^{
                UIViewController* vc = [UIViewController new];
                [self presentViewController:vc animated:NO completion:nil];
                [self dismissViewControllerAnimated:NO completion:nil];
            }, 0.1);
        });
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    // Translations
    [self.titleTextView setFormattedText:[self.sessionManager translation:kTitleText formatParams:nil]];
    [self.skipButton setTitle:[self.sessionManager translation:kSkipText formatParams:nil] forState:UIControlStateNormal];
}

@end
