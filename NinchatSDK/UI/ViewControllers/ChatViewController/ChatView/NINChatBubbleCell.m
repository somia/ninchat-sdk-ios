//
//  NINChatBubbleCell.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AFNetworking;

#import "NINChatBubbleCell.h"
#import "NINUtils.h"

@interface NINChatBubbleCell ()

// Width constraint for the left avatar area; used to hide the left avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* leftAvatarWidthConstraint;

// Width constraint for the right avatar area; used to hide the right avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* rightAvatarWidthConstraint;

// The bubble container view
@property (nonatomic, strong) IBOutlet UIView* containerView;

// The left side avatar container view
@property (nonatomic, strong) IBOutlet UIView* leftAvatarContainerView;

// The right side avatar container view
@property (nonatomic, strong) IBOutlet UIView* rightAvatarContainerView;

// The chat bubble graphic
@property (nonatomic, strong) IBOutlet UIImageView* bubbleImageView;

// The left avatar image
@property (nonatomic, strong) IBOutlet UIImageView* leftAvatarImageView;

// The right avatar image
@property (nonatomic, strong) IBOutlet UIImageView* rightAvatarImageView;

// The text container label
@property (nonatomic, strong) IBOutlet UILabel* textContentLabel;

// Left side constraint for the bubble container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* containerLeftConstraint;

// Right side constraint for the bubble container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* containerRightConstraint;

// Right side constraint for the label
//@property (nonatomic, strong) IBOutlet NSLayoutConstraint* textRightConstraint;

// Original width of the avatar image containers
@property (nonatomic, assign) CGFloat avatarContainerWidth;

@end

@implementation NINChatBubbleCell

-(void) populateWithText:(NSString*)text avatarImageUrl:(NSString*)avatarImageUrl isMine:(BOOL)isMine {
    self.textContentLabel.text = text;

    if (isMine) {
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_right" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];

        // Push the bubble to the right edge by setting the left constraint relation to >=
        self.containerLeftConstraint.active = NO;
        self.containerLeftConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.leftAvatarContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
        self.containerLeftConstraint.active = YES;

        self.rightAvatarWidthConstraint.constant = 50;
        self.leftAvatarWidthConstraint.constant = 0;

        self.leftAvatarImageView.image = nil;
        [self.rightAvatarImageView setImageWithURL:[NSURL URLWithString:avatarImageUrl] placeholderImage:[UIImage imageNamed:@"icon_portrait_placeholder" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil]];
    } else {
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_left" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];
        self.leftAvatarWidthConstraint.constant = self.avatarContainerWidth;

        // Push the bubble to the left edge by setting the right constraint relation to >=
        self.containerRightConstraint.active = NO;
        self.containerRightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
        self.containerRightConstraint.active = YES;

        self.rightAvatarWidthConstraint.constant = 0;
        self.leftAvatarWidthConstraint.constant = 50;

        [self.leftAvatarImageView setImageWithURL:[NSURL URLWithString:avatarImageUrl] placeholderImage:[UIImage imageNamed:@"icon_portrait_placeholder" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil]];
        self.rightAvatarImageView.image = nil;
    }
}

-(void) awakeFromNib {
    [super awakeFromNib];

    self.avatarContainerWidth = self.leftAvatarWidthConstraint.constant;
}

@end
