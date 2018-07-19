//
//  NINBaseViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINBaseViewController.h"
#import "NINSessionManager.h"
#import "NINNavigationBar.h"

@interface NINBaseViewController ()

@property (nonatomic, weak) id<UIGestureRecognizerDelegate> previousPopGestureDelegate;

@end

@implementation NINBaseViewController

#pragma mark - IBAction handlers

#pragma mark - Lifecycle etc.

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.interactivePopGestureRecognizer.delegate = self.previousPopGestureDelegate;
}

//-(void) viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//
//    [self.navigationController setNavigationBarHidden:YES];
//}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.previousPopGestureDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;

    if (self.navigationController.viewControllers.count > 1) {
        // Enable default back gesture even without navigation bar
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;
    self.customNavigationBar.closeButtonPressedCallback = ^{
        [weakSelf.sessionManager closeChat];
    };
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
