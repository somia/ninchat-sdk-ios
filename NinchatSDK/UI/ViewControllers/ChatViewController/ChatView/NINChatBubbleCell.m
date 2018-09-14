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
#import "NINChatView.h"

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

// The sender's name label
@property (nonatomic, strong) IBOutlet UILabel* senderNameLabel;

// The message time stamp label
@property (nonatomic, strong) IBOutlet UILabel* timeLabel;

// The text container label
@property (nonatomic, strong) IBOutlet UILabel* textContentLabel;

// Constraint for binding sender name / time labels to left edge
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topLabelsLeftConstraint;

// Constraint for binding sender name / time labels to right edge
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topLabelsRightConstraint;

// Left side constraint for the bubble container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* containerLeftConstraint;

// Right side constraint for the bubble container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* containerRightConstraint;

// Original width of the avatar image containers
@property (nonatomic, assign) CGFloat avatarContainerWidth;

@end

@implementation NINChatBubbleCell

#pragma mark - Private methods

-(void) configureForMyMessage:(id<NINChatViewMessage>)message {
    self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_right" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];

    self.topLabelsLeftConstraint.active = NO;
    self.topLabelsRightConstraint.active = YES;

    // White text on black bubble
    self.bubbleImageView.tintColor = [UIColor colorWithWhite:0 alpha:1];
    self.textContentLabel.textColor = [UIColor colorWithWhite:1 alpha:1];

    // Push the bubble to the right edge by setting the left constraint relation to >=
    self.containerLeftConstraint.active = NO;
    self.containerLeftConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.leftAvatarContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    self.containerLeftConstraint.active = YES;

    self.leftAvatarContainerView.hidden = YES;
    self.rightAvatarContainerView.hidden = NO;

    self.leftAvatarImageView.image = nil;
    [self.rightAvatarImageView setImageWithURL:[NSURL URLWithString:message.avatarURL] placeholderImage:[UIImage imageNamed:@"icon_avatar_mine" inBundle:findResourceBundle() compatibleWithTraitCollection:nil]];
}

-(void) configureForOthersMessage:(id<NINChatViewMessage>)message {
    self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_left" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    self.leftAvatarWidthConstraint.constant = self.avatarContainerWidth;

    self.topLabelsRightConstraint.active = NO;
    self.topLabelsLeftConstraint.active = YES;

    // Black text on white bubble
    self.bubbleImageView.tintColor = [UIColor colorWithWhite:1 alpha:1];
    self.textContentLabel.textColor = [UIColor colorWithWhite:0 alpha:1];

    // Push the bubble to the left edge by setting the right constraint relation to >=
    self.containerRightConstraint.active = NO;
    self.containerRightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    self.containerRightConstraint.active = YES;

    self.leftAvatarContainerView.hidden = NO;
    self.rightAvatarContainerView.hidden = YES;

    [self.leftAvatarImageView setImageWithURL:[NSURL URLWithString:message.avatarURL] placeholderImage:[UIImage imageNamed:@"icon_avatar_other" inBundle:findResourceBundle() compatibleWithTraitCollection:nil]];
    self.rightAvatarImageView.image = nil;
}

#pragma mark - Public methods

-(void) populateWithMessage:(id<NINChatViewMessage>)message {
    self.textContentLabel.text = message.textContent;
    self.senderNameLabel.text = message.senderName;
    if (self.senderNameLabel.text.length < 1) {
        self.senderNameLabel.text = @"Guest";
    }

    NSCAssert(self.topLabelsLeftConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsRightConstraint != nil, @"Cannot be nil");

    if (message.mine) {
        // Visitor's (= phone user) message - on the right
        [self configureForMyMessage:message];
    } else {
        // Other's message - on the left
        [self configureForOthersMessage:message];
    }

    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];

    //
//    [self.contentView setNeedsLayout];
//    [self.contentView layoutIfNeeded];
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    self.avatarContainerWidth = self.leftAvatarWidthConstraint.constant;

    // Make the avatar image views circles
    self.leftAvatarImageView.layer.cornerRadius = self.leftAvatarImageView.bounds.size.height / 2;
    self.leftAvatarImageView.layer.masksToBounds = YES;
    self.rightAvatarImageView.layer.cornerRadius = self.rightAvatarImageView.bounds.size.height / 2;
    self.rightAvatarImageView.layer.masksToBounds = YES;

    // Rotate the cell 180 degrees; we will use the table view upside down
    self.transform = CGAffineTransformMakeRotation(M_PI);

    // The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
    self.layer.shouldRasterize = YES;
}

@end
