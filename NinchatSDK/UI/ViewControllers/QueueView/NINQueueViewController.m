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

static NSString* const kSegueIdQueueToChat = @"ninchatsdk.segue.QueueToChat";

@interface NINQueueViewController ()

@property (nonatomic, strong) IBOutlet UIImageView* spinnerImageView;
@property (nonatomic, strong) IBOutlet UILabel* queueInfoLabel;
@property (nonatomic, strong) IBOutlet UILabel* inQueueTextLabel;

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
            weakSelf.queueInfoLabel.text = [self.sessionManager translation:@"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next." formatParams:@{@"audienceQueue.queue_attrs.name": self.queueToJoin.name}];
        } else {
            weakSelf.queueInfoLabel.text = [self.sessionManager translation:@"Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}." formatParams:@{@"audienceQueue.queue_position": @(queuePosition).stringValue, @"audienceQueue.queue_attrs.name": self.queueToJoin.name}];
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
    self.inQueueTextLabel.text = self.sessionManager.siteConfiguration[@"default"][@"inQueueText"];

    self.queueInfoLabel.text = nil;
}

@end
