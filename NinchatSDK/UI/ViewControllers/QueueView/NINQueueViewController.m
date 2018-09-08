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

    NINQueue* queue = self.queueToJoin;

    //TODO better handling here; prevent back gesture from chat view?
    if (queue == nil) {
        // Nothing to do; this is the case after we have popped the chat controller
        return;
    }
    self.queueToJoin = nil;

    // Connect to the queue
    __weak typeof(self) weakSelf = self;
    [self.sessionManager joinQueueWithId:queue.queueId progress:^(NSError * _Nullable error, NSInteger queuePosition) {
        NSLog(@"Queue progress: position: %ld", (long)queuePosition);

        if (queuePosition == 1) {
            weakSelf.queueInfoLabel.text = [NSString stringWithFormat:@"Joined audience queue %@, you are next.", queue.name];
        } else {
            weakSelf.queueInfoLabel.text = [NSString stringWithFormat:@"Joined audience queue %@, you are at position %ld.", queue.name, queuePosition];
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

    self.queueInfoLabel.text = nil;
}

@end
