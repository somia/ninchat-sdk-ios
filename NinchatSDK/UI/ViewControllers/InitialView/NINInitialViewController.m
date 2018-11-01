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
#import "UITextView+Ninchat.h"
#import "NINUtils.h"
#import "UIButton+Ninchat.h"

// UI strings
static NSString* const kJoinQueueText = @"Join audience queue {{audienceQueue.queue_attrs.name}}";
static NSString* const kCloseWindowText = @"Close window";

// Segue id to open queue view
static NSString* const kSegueIdInitialToQueue = @"ninchatsdk.InitialToQueue";

@interface NINInitialViewController () 

@property (nonatomic, strong) IBOutlet UIView* topContainerView;
@property (nonatomic, strong) IBOutlet UIView* bottomContainerView;
@property (nonatomic, strong) IBOutlet UITextView* welcomeTextView;
@property (nonatomic, strong) IBOutlet UIButton* startChatButton;
@property (nonatomic, strong) IBOutlet UIButton* closeWindowButton;
@property (nonatomic, strong) IBOutlet UITextView* motdTextView;

@end

@implementation NINInitialViewController

#pragma mark - Private methods

-(void) applyAssetOverrides {
//    [self.startChatButton overrideAssetsWithSession:self.sessionManager.ninchatSession assetKey:NINImageAssetKeyInitialViewJoinQueueButton isPrimaryButton:YES];
//    [self.closeWindowButton overrideAssetsWithSession:self.sessionManager.ninchatSession assetKey:NINImageAssetKeyInitialViewCloseWindowButton isPrimaryButton:NO];

    UIColor* topBackgroundColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetBackgroundTop];
    if (topBackgroundColor != nil) {
        self.topContainerView.backgroundColor = topBackgroundColor;
    }

    UIColor* bottomBackgroundColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetBackgroundBottom];
    if (bottomBackgroundColor != nil) {
        self.bottomContainerView.backgroundColor = bottomBackgroundColor;
    }

    UIColor* textTopColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetTextTop];
    if (textTopColor != nil) {
        self.welcomeTextView.textColor = textTopColor;
    }

    UIColor* textBottomColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetTextBottom];
    if (textBottomColor != nil) {
        self.motdTextView.textColor = textBottomColor;
    }

    UIColor* linkColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetLink];
    if (linkColor != nil) {
        self.welcomeTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
        self.motdTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
    }
}

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

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdInitialToQueue]) {
        NINQueueViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
        vc.queueToJoin = (NINQueue*)sender;
    }
}

#pragma mark - Lifecycle etc.

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
    NSString* welcomeText = (NSString*)self.sessionManager.siteConfiguration[@"default"][@"welcome"];;
    [self.welcomeTextView setFormattedText:welcomeText];
    self.welcomeTextView.delegate = self;
    [self.closeWindowButton setTitle:[self.sessionManager translation:kCloseWindowText formatParams:nil]  forState:UIControlStateNormal];
    if (self.sessionManager.queues.count > 0) {
        [self.startChatButton setTitle:[self.sessionManager translation:kJoinQueueText formatParams:@{@"audienceQueue.queue_attrs.name": self.sessionManager.queues[0].name}] forState:UIControlStateNormal];
    }
    [self.motdTextView setFormattedText:self.sessionManager.siteConfiguration[@"default"][@"motd"]];
    self.motdTextView.delegate = self;

    // Rounded button corners
    self.startChatButton.layer.cornerRadius = self.startChatButton.bounds.size.height / 2;
    self.closeWindowButton.layer.cornerRadius = self.closeWindowButton.bounds.size.height / 2;
    self.closeWindowButton.layer.borderColor = [UIColor colorWithRed:73/255.0 green:172/255.0 blue:253/255.0 alpha:1].CGColor;
    self.closeWindowButton.layer.borderWidth = 1;

    // Apply asset overrides
    [self applyAssetOverrides];
}

@end
