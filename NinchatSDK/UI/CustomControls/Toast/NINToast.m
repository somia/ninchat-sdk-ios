//
//  NINToast.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINToast.h"
#import "NINUtils.h"

@interface NINToast ()

@property (nonatomic, strong) IBOutlet UIView* containerView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topInsetHeightConstraint;
@property (nonatomic, strong) IBOutlet UILabel* messageLabel;

@end

static const NSTimeInterval kAnimationDuration = 0.3;
static const NSTimeInterval kToastDuration = 1.5;
static const CGFloat kHiddenAlpha = 0.6;

@implementation NINToast

+(NINToast*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINToast" owner:nil options:nil];

    NSCAssert([objects.firstObject isKindOfClass:[NINToast class]], @"Invalid class resource");

    return (NINToast*)objects.firstObject;
}

+(void) showWithMessage:(NSString*)message bgColorOverride:(UIColor*)color callback:(emptyBlock)callback {
    NSCAssert(UIApplication.sharedApplication.keyWindow != nil, @"No key window");

    NINToast* toast = [NINToast loadViewFromNib];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.messageLabel.text = message;

    if (color != nil) {
        toast.containerView.backgroundColor = color;
    }

    UIView* window = UIApplication.sharedApplication.keyWindow;
    [window addSubview:toast];

    if (@available(iOS 11.0, *)) {
        // Add filler space on top of toast to match the safe area inset
        toast.topInsetHeightConstraint.constant = window.safeAreaInsets.top;
    }

    NSArray* constraints = @[ constrain(toast, window, NSLayoutAttributeLeft),
                              constrain(toast, window, NSLayoutAttributeTop),
                              constrain(toast, window, NSLayoutAttributeRight) ];
    [NSLayoutConstraint activateConstraints:constraints];

    CGFloat toastBottom = toast.frame.origin.y + toast.bounds.size.height;
    CGAffineTransform hiddenTransform = CGAffineTransformMakeTranslation(0, -toastBottom);

    toast.transform = hiddenTransform;
    toast.alpha = kHiddenAlpha;

    // Animate the toast into view
    [UIView animateWithDuration:kAnimationDuration animations:^{
        toast.transform = CGAffineTransformIdentity;
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        // After a delay, animate the toast out of sight again
        [UIView animateWithDuration:kAnimationDuration delay:kToastDuration options:0 animations:^{
            toast.transform = hiddenTransform;
            toast.alpha = kHiddenAlpha;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
            if (callback != nil) {
                callback();
            }
        }];
    }];
}

+(void) showWithErrorMessage:(NSString*)message callback:(emptyBlock)callback {
    [NINToast showWithMessage:message bgColorOverride:nil callback:callback];
}

+(void) showWithInfoMessage:(NSString*)message callback:(emptyBlock)callback {
    [NINToast showWithMessage:message bgColorOverride:[UIColor colorWithRed:0 green:138/255.0 blue:1 alpha:1] callback:callback];
}

@end
