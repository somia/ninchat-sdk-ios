//
//  NINComposeInputView.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINComposeInputView.h"

CGFloat buttonHeight = 45;
CGFloat verticalMargin = 10;

@interface NINComposeInputView ()

@property (nonatomic, strong) NSArray<NSDictionary*>* options;

@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIButton* sendButton;
@property (nonatomic, strong) NSArray<UIButton*>* optionButtons;

@end

@implementation NINComposeInputView

-(CGFloat) intrinsicHeight {
    // + 1 to button count from send button, additional margins top and bottom
    return self.titleLabel.intrinsicContentSize.height
        + (self.optionButtons.count + 1) * buttonHeight
        + (self.optionButtons.count + 1) * verticalMargin;
}

-(CGSize) intrinsicContentSize {
    if (self.optionButtons != nil) {
        return CGSizeMake(CGFLOAT_MAX, [self intrinsicHeight]);
    } else {
        return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    }
}

-(void) layoutSubviews {
    [super layoutSubviews];
    CGFloat titleHeight = self.titleLabel.intrinsicContentSize.height;
    self.titleLabel.frame = CGRectMake(0, 0, self.titleLabel.intrinsicContentSize.width, titleHeight);
    CGFloat y = titleHeight + verticalMargin;
    for (UIButton* button in self.optionButtons) {
        button.frame = CGRectMake(0, y, self.bounds.size.width, buttonHeight);
        y += buttonHeight + verticalMargin;
    }
    CGFloat sendButtonWidth = self.sendButton.intrinsicContentSize.width;
    self.sendButton.frame = CGRectMake(self.bounds.size.width - sendButtonWidth, y, sendButtonWidth, buttonHeight);
}

-(void) clear {
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    self.optionButtons = nil;
}

-(void) populateWithLabel:(NSString*)label options:(NSArray<NSDictionary*>*)options {
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] init];
        [self addSubview:self.titleLabel];
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.sendButton];
    }
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    
    NSMutableArray<UIButton*>* optionButtons = [NSMutableArray new];
    for (NSDictionary* option in options) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:option[@"label"] forState:UIControlStateNormal];
        [self addSubview:button];
        [optionButtons addObject:button];
    }
    self.optionButtons = optionButtons;
}



@end
