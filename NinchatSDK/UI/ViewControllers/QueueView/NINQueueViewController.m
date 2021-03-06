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
static NSString* const kNoQueueText = @"noQueuesText";
static NSString* const kQueuePositionN = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}.";
static NSString* const kQueuePositionNext = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next.";
static NSString* const kCloseChatText = @"Close chat";

static NSString* const kSegueIdQueueToChat = @"ninchatsdk.segue.QueueToChat";

@interface NINQueueViewController ()

@property (nonatomic, strong) IBOutlet UIView* topContainerView;
@property (nonatomic, strong) IBOutlet UIView* bottomContainerView;
@property (nonatomic, strong) IBOutlet UIImageView* spinnerImageView;
@property (nonatomic, strong) IBOutlet UITextView* queueInfoTextView;
@property (nonatomic, strong) IBOutlet UITextView* motdTextView;
@property (nonatomic, strong) IBOutlet NINCloseChatButton* closeChatButton;
@property (nonatomic, strong) id<NSObject> queueTransferListener;

@end

@implementation NINQueueViewController

#pragma mark - Private methods

-(void) applyAssetOverrides {
    UIImage* progressImage = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconLoader];
    if (progressImage != nil) {
        self.spinnerImageView.image = progressImage;
    }

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
        self.queueInfoTextView.textColor = textTopColor;
    }

    UIColor* textBottomColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetTextBottom];
    if (textBottomColor != nil) {
        self.motdTextView.textColor = textBottomColor;
    }

    UIColor* linkColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetLink];
    if (linkColor != nil) {
        self.queueInfoTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
        self.motdTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
    }

    [self.closeChatButton setButtonTitle:[self.sessionManager translation:kCloseChatText formatParams:nil]];
    [self.closeChatButton overrideAssetsWithSession:self.sessionManager.ninchatSession];
}

/// https://github.com/somia/ninchat-sdk-ios/issues/68
-(void) connectToQueue:(NINQueue*)queue {
    if (queue.isClosed) {
        [self.queueInfoTextView setFormattedText:[self.sessionManager.siteConfiguration valueForKey:kNoQueueText]];
        return;
    }
    [self connectToQueueWithId:queue.queueID];
}

- (void)connectToQueueWithId:(NSString*)queueID {
    __weak typeof(self) weakSelf = self;
    [self.sessionManager joinQueueWithId:queueID progress:^(NSError * _Nullable error, NSInteger queuePosition) {

        if (error != nil) {
            // Failed to join the queue
            [self.sessionManager.ninchatSession sdklog:@"Failed to join the queue: %@", error];
        }

        if (queuePosition == 1) {
            [weakSelf.queueInfoTextView setFormattedText:[weakSelf.sessionManager translation:kQueuePositionNext formatParams:@{@"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}]];
        } else {
            [weakSelf.queueInfoTextView setFormattedText:[weakSelf.sessionManager translation:kQueuePositionN formatParams:@{@"audienceQueue.queue_position": @(queuePosition).stringValue, @"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}]];
        }

        // Apply color override
        UIColor* textTopColor = [weakSelf.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetTextTop];
        if (textTopColor != nil) {
            weakSelf.queueInfoTextView.textColor = textTopColor;
        }
    } channelJoined:^{
        [weakSelf performSegueWithIdentifier:kSegueIdQueueToChat sender:nil];
        // Listen to new queue events to handle possible transfers later
        if (self.queueTransferListener == nil) {
            self.queueTransferListener = fetchNotification(kNINQueuedNotification, ^BOOL(NSNotification* notification) {
                [weakSelf connectToQueueWithId:[notification.userInfo valueForKey:@"queue_id"]];
                return NO;
            });
        }
    }];
    
}

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

    self.queueInfoTextView.delegate = self;
    self.motdTextView.delegate = self;
    
    // Translations
    NSString* inQueueText = [self.sessionManager.siteConfiguration valueForKey:@"inQueueText"];
    if (inQueueText != nil) {
        [self.motdTextView setFormattedText:inQueueText];
    } else {
        [self.motdTextView setFormattedText:[self.sessionManager.siteConfiguration valueForKey:@"motd"]];
    }
    self.queueInfoTextView.text = nil;
    self.queueInfoTextView.hidden = NO;

    __weak typeof(self) weakSelf = self;
    self.closeChatButton.pressedCallback = ^{
        [weakSelf.sessionManager leaveCurrentQueueWithCompletionCallback:^(NSError* error) {
            [weakSelf.sessionManager closeChat];
            weakSelf.queueTransferListener = nil;
            [[NSNotificationCenter defaultCenter] removeObserver:weakSelf name:kNINQueuedNotification object:nil];
        }];
    };

    // Apply asset overrides
    [self applyAssetOverrides];
    
    // Connect to the queue
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNINQueuedNotification object:nil];
    [self connectToQueue:self.queueToJoin];
}

@end
