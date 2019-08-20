//
//  NINComposeInputView.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINComposeInputView.h"
#import "NINUtils.h"

static CGFloat const kButtonHeight = 45;
static CGFloat const kVerticalMargin = 10;

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
        + (self.optionButtons.count + 1) * kButtonHeight
        + (self.optionButtons.count + 1) * kVerticalMargin;
}

-(CGSize) intrinsicContentSize {
    if (self.optionButtons != nil) {
        return CGSizeMake(CGFLOAT_MAX, [self intrinsicHeight]);
    } else {
        return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    }
}

-(void) applyButtonStyle:(UIButton*)button selected:(BOOL)selected {
    // TODO read session object for colors
    button.layer.cornerRadius = kButtonHeight / 2;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    if (selected) {
        button.layer.borderWidth = 0;
        [button setBackgroundImage:imageFrom([UIColor blueColor]) forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        button.layer.borderWidth = 2;
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
}

-(void) layoutSubviews {
    [super layoutSubviews];
    CGFloat titleHeight = self.titleLabel.intrinsicContentSize.height;
    self.titleLabel.frame = CGRectMake(0, 0, self.titleLabel.intrinsicContentSize.width, titleHeight);
    CGFloat y = titleHeight + kVerticalMargin;
    for (UIButton* button in self.optionButtons) {
        button.frame = CGRectMake(0, y, self.bounds.size.width, kButtonHeight);
        y += kButtonHeight + kVerticalMargin;
    }
    CGFloat sendButtonWidth = self.sendButton.intrinsicContentSize.width;
    self.sendButton.frame = CGRectMake(self.bounds.size.width - sendButtonWidth, y, sendButtonWidth, kButtonHeight);
}

-(void) clear {
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    self.optionButtons = nil;
}

-(void) populateWithLabel:(NSString*)label options:(NSArray<NSDictionary*>*)options colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets {
    // TODO read session object
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
        self.titleLabel.textColor = [UIColor blackColor];
        UIColor* bubbleTextColor = colorAssets[NINColorAssetKeyChatBubbleLeftText];
        if (bubbleTextColor != nil) {
            self.titleLabel.textColor = bubbleTextColor;
        }
        [self addSubview:self.titleLabel];
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // TODO get send button text from session object
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [self applyButtonStyle:self.sendButton selected:false];
        self.sendButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
        [self.sendButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.sendButton.layer.borderColor = [[UIColor blueColor] CGColor];
        [self addSubview:self.sendButton];
    }
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    
    [self.titleLabel setText:label];
    
    NSMutableArray<UIButton*>* optionButtons = [NSMutableArray new];
    for (NSDictionary* option in options) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
        [self applyButtonStyle:button selected:false];
        [button setTitle:option[@"label"] forState:UIControlStateNormal];
        [self addSubview:button];
        [optionButtons addObject:button];
    }
    self.optionButtons = optionButtons;
}



@end
