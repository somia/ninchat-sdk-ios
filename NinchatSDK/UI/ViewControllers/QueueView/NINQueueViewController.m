//
//  QueueViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINQueueViewController.h"
#import "NINSessionManager.h"
#import "NINChatViewController.h"
#import "NINUtils.h"
#import "NINChatViewController.h"
#import "NINQueue.h"
#import "NINCloseChatButton.h"
#import "UITextView+Ninchat.h"
#import "UIButton+Ninchat.h"

// UI strings
static NSString* const kQueuePositionN = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}.";
static NSString* const kQueuePositionNext = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next.";

static NSString* const kSegueIdQueueToChat = @"ninchatsdk.segue.QueueToChat";

@interface NINQueueViewController ()

@property (nonatomic, strong) IBOutlet UIImageView* spinnerImageView;
@property (nonatomic, strong) IBOutlet UITextView* queueInfoTextView;
@property (nonatomic, strong) IBOutlet UITextView* motdTextView;
@property (nonatomic, strong) IBOutlet NINCloseChatButton* closeChatButton;

@end

@implementation NINQueueViewController

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdQueueToChat]) {
        NINChatViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
    }
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Connect to the queue
    __weak typeof(self) weakSelf = self;
    [self.sessionManager joinQueueWithId:self.queueToJoin.queueID progress:^(NSError * _Nullable error, NSInteger queuePosition) {
        NSLog(@"Queue progress: position: %ld", (long)queuePosition);

        if (queuePosition == 1) {
            [weakSelf.queueInfoTextView setFormattedText:[weakSelf.sessionManager translation:kQueuePositionNext formatParams:@{@"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}]];
        } else {
            [weakSelf.queueInfoTextView setFormattedText:[weakSelf.sessionManager translation:kQueuePositionN formatParams:@{@"audienceQueue.queue_position": @(queuePosition).stringValue, @"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}]];
        }
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        [weakSelf performSegueWithIdentifier:kSegueIdQueueToChat sender:nil];
    }];

    // Look for customized images
    UIImage* progressImage = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyQueueViewProgressIndicator];
    if (progressImage != nil) {
        self.spinnerImageView.image = progressImage;
    }

    // Spin the whirl icon continuoysly
    if ([self.spinnerImageView.layer animationForKey:@"SpinAnimation"] == nil) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = @(0.0);
        animation.toValue = @(2*M_PI);
        animation.duration = 3.0f;
        animation.repeatCount = INFINITY;
        [self.spinnerImageView.layer addAnimation:animation forKey:@"SpinAnimation"];
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    NSCAssert(self.sessionManager != nil, @"Must have session manager set");

    // Translations
    NSString* inQueueText = self.sessionManager.siteConfiguration[@"default"][@"inQueueText"];
    if (inQueueText != nil) {
        [self.motdTextView setFormattedText:inQueueText];
    } else {
        [self.motdTextView setFormattedText:self.sessionManager.siteConfiguration[@"default"][@"motd"]];
    }
    self.queueInfoTextView.text = nil;

    __weak typeof(self) weakSelf = self;
    self.closeChatButton.pressedCallback = ^{
        NSLog(@"Queue view: Close chat button pressed!");
        [weakSelf.sessionManager leaveCurrentQueueWithCompletionCallback:^(NSError* error) {
            [weakSelf.sessionManager closeChat];
        }];
    };

    // Asset overrides
    [self.closeChatButton overrideAssetsWithSession:self.sessionManager.ninchatSession];
}

@end
