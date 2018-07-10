//
//  NINBaseViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINBaseViewController.h"

@interface NINBaseViewController ()

@property (nonatomic, weak) id<UIGestureRecognizerDelegate> previousPopGestureDelegate;

@end

@implementation NINBaseViewController

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.interactivePopGestureRecognizer.delegate = self.previousPopGestureDelegate;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.previousPopGestureDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;

    if (self.navigationController.viewControllers.count > 1) {
        // Enable default back gesture even without navigation bar
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

@end
