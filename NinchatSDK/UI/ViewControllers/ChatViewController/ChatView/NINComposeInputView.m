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

// properties that should be static const but can't be initialised compile-time
@property (nonatomic, strong) UIColor* buttonBlue;
@property (nonatomic, strong) UIColor* buttonGrey;
@property (nonatomic, strong) UIFont* labelFont;

// compose options received from the backend and displayed
@property (nonatomic, strong) NSArray<NSMutableDictionary*>* options;

// subviews
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
    button.layer.cornerRadius = kButtonHeight / 2;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = self.buttonGrey.CGColor;
    if (selected) {
        button.layer.borderWidth = 0;
        [button setBackgroundImage:imageFrom(self.buttonBlue) forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        button.layer.borderWidth = 2;
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setTitleColor:self.buttonGrey forState:UIControlStateNormal];
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
    
    CGFloat sendButtonWidth = self.sendButton.intrinsicContentSize.width + 60;
    self.sendButton.frame = CGRectMake(self.bounds.size.width - sendButtonWidth, y, sendButtonWidth, kButtonHeight);
}

-(void) clear {
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    self.options = nil;
    self.optionButtons = nil;
}

-(void) pressed:(UIButton*)button {
    if (button == self.sendButton) {
        NSLog(@"TODO send %@", self.options);
        [self applyButtonStyle:button selected:YES];
        return;
    }
    for (int i=0; i<self.optionButtons.count; ++i) {
        if (button == self.optionButtons[i]) {
            BOOL selected = ![[self.options[i] valueForKey:@"selected"] boolValue];
            self.options[i][@"selected"] = [NSNumber numberWithBool:selected];
            [self applyButtonStyle:button selected:selected];
            return;
        }
    }
}

-(void) populateWithLabel:(NSString*)label options:(NSArray<NSDictionary*>*)options siteConfiguration:(NSDictionary*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets {
    
    // create title label and send button once
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = self.labelFont;
        self.titleLabel.textColor = [UIColor blackColor];
        UIColor* bubbleTextColor = colorAssets[NINColorAssetKeyChatBubbleLeftText];
        if (bubbleTextColor != nil) {
            self.titleLabel.textColor = bubbleTextColor;
        }
        [self addSubview:self.titleLabel];
        
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString* sendButtonText = siteConfiguration[@"default"][@"sendButtonText"];
        if (sendButtonText != nil) {
            [self.sendButton setTitle:sendButtonText forState:UIControlStateNormal];
        } else {
            [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        }
        [self applyButtonStyle:self.sendButton selected:false];
        self.sendButton.titleLabel.font = self.labelFont;
        [self.sendButton setTitleColor:self.buttonBlue forState:UIControlStateNormal];
        self.sendButton.layer.borderColor = self.buttonBlue.CGColor;
        [self.sendButton addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.sendButton];
    }
    [self.titleLabel setText:label];

    // clear existing option buttons
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    
    // recreate options dict to add the "selected" fields
    NSMutableArray<NSMutableDictionary*>* newOptions = [NSMutableArray new];
    NSMutableArray<UIButton*>* optionButtons = [NSMutableArray new];
    
    for (NSDictionary* option in options) {
        NSMutableDictionary* newOption = [option mutableCopy];
        newOption[@"selected"] = @NO;
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = self.labelFont;
        [self applyButtonStyle:button selected:false];
        [button setTitle:option[@"label"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        [newOptions addObject:newOption];
        [optionButtons addObject:button];
    }
    
    self.options = newOptions;
    self.optionButtons = optionButtons;
}

-(void) awakeFromNib {
    [super awakeFromNib];
    self.buttonBlue = [UIColor colorWithRed:(CGFloat)0x49/0xFF green:(CGFloat)0xAC/0xFF blue:(CGFloat)0xFD/0xFF alpha:1];
    self.buttonGrey = [UIColor colorWithRed:(CGFloat)0x99/0xFF green:(CGFloat)0x99/0xFF blue:(CGFloat)0x99/0xFF alpha:1];
    /*
     This should be source sans pro, but the custom font fails to initialise.
     It appears it's actually borken everywhere else too, so for the sake of
     getting this feature out we'll just match the current look for now.
     */
    self.labelFont = [UIFont fontWithName:@"Helvetica" size:16];;
}

@end
