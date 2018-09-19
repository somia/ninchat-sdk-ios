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

@end

@implementation NINBaseViewController

#pragma mark - Private methods

-(void) keyboardWillShow:(NSNotification*)notification {
    CGSize keyboardSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:animationDuration animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -keyboardSize.height);
    } completion:^(BOOL finished) {

    }];
}

-(void) keyboardWillHide:(NSNotification*)notification {
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:animationDuration animations:^{
        self.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Lifecycle etc.

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
