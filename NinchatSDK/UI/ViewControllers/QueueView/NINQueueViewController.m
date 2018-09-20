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

// UI strings
static NSString* const kQueuePositionN = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}.";
static NSString* const kQueuePositionNext = @"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next.";

static NSString* const kSegueIdQueueToChat = @"ninchatsdk.segue.QueueToChat";

@interface NINQueueViewController ()

@property (nonatomic, strong) IBOutlet UIImageView* spinnerImageView;
@property (nonatomic, strong) IBOutlet UILabel* queueInfoLabel;
@property (nonatomic, strong) IBOutlet UILabel* inQueueTextLabel;
@property (nonatomic, strong) IBOutlet UILabel* motdLabel;
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

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Connect to the queue
    __weak typeof(self) weakSelf = self;
    [self.sessionManager joinQueueWithId:self.queueToJoin.queueId progress:^(NSError * _Nullable error, NSInteger queuePosition) {
        NSLog(@"Queue progress: position: %ld", (long)queuePosition);

        if (queuePosition == 1) {
            weakSelf.queueInfoLabel.text = [weakSelf.sessionManager translation:kQueuePositionNext formatParams:@{@"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}];
        } else {
            weakSelf.queueInfoLabel.text = [weakSelf.sessionManager translation:kQueuePositionN formatParams:@{@"audienceQueue.queue_position": @(queuePosition).stringValue, @"audienceQueue.queue_attrs.name": weakSelf.queueToJoin.name}];
        }
    } channelJoined:^{
        NSLog(@"Channel joined - showing the chat UI");

        [weakSelf performSegueWithIdentifier:kSegueIdQueueToChat sender:nil];
    }];

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

    // Translations
    //TODO support HTML styling
    self.inQueueTextLabel.text = self.sessionManager.siteConfiguration[@"default"][@"inQueueText"];

    //TODO support HTML styling
    self.motdLabel.text = self.sessionManager.siteConfiguration[@"default"][@"motd"];

    self.queueInfoLabel.text = nil;

    __weak typeof(self) weakSelf = self;
    self.closeChatButton.pressedCallback = ^{
        NSLog(@"Queue view: Close chat button pressed!");
        [weakSelf.sessionManager closeChat];
    };
}

@end
