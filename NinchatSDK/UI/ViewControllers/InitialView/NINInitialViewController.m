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
#import "NSString+Ninchat.h"

// UI strings
static NSString* const kJoinQueueText = @"Join audience queue {{audienceQueue.queue_attrs.name}}";
static NSString* const kCloseWindowText = @"Close window";

// Segue id to open queue view
static NSString* const kSegueIdInitialToQueue = @"ninchatsdk.InitialToQueue";

@interface NINInitialViewController () <UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UILabel* welcomeTextLabel;
@property (nonatomic, strong) IBOutlet UIButton* startChatButton;
@property (nonatomic, strong) IBOutlet UIButton* closeWindowButton;

//TODO figure out which text this is and rename
@property (nonatomic, strong) IBOutlet UITextView* bottomTextView;

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

#pragma mark - From UITextViewDelegate

// Pre-iOS 10
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
}

// iOS 10 and up
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0)) {
    return YES;
}

#pragma mark - Lifecycle etc.

-(void) viewDidLoad {
    [super viewDidLoad];

    // Translations
    self.welcomeTextLabel.text = (NSString*)self.sessionManager.siteConfiguration[@"default"][@"welcome"];
    [self.closeWindowButton setTitle:[self.sessionManager translation:kCloseWindowText formatParams:nil]  forState:UIControlStateNormal];
    if (self.sessionManager.queues.count > 0) {
        [self.startChatButton setTitle:[self.sessionManager translation:kJoinQueueText formatParams:@{@"audienceQueue.queue_attrs.name": self.sessionManager.queues[0].name}] forState:UIControlStateNormal];
    }

    //TODO use translation
    NSString* text = @"<center><b>Well hello there!</b><br><br>This is example of HTML formatted text with link support.<br><br>Contact email: <a href=\"mailto:matti@qvik.fi\">matti@qvik.fi</a><br><br>Or call me: <a href=\"tel:+358405216859\">+358405216859</a> </center>";
    self.bottomTextView.attributedText = [text htmlAttributedStringWithFont:self.bottomTextView.font];
    self.bottomTextView.delegate = self;

    self.startChatButton.layer.cornerRadius = self.startChatButton.bounds.size.height / 2;
    self.closeWindowButton.layer.cornerRadius = self.closeWindowButton.bounds.size.height / 2;
    self.closeWindowButton.layer.borderColor = [UIColor colorWithRed:73/255.0 green:172/255.0 blue:253/255.0 alpha:1].CGColor;
    self.closeWindowButton.layer.borderWidth = 1;
}

@end
