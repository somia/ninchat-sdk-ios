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
        // Visitor's (= phone user) message - on the right
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_right" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];

        // White text on black bubble
        self.bubbleImageView.tintColor = [UIColor colorWithWhite:0 alpha:1];
        self.textContentLabel.textColor = [UIColor colorWithWhite:1 alpha:1];

        // Push the bubble to the right edge by setting the left constraint relation to >=
        self.containerLeftConstraint.active = NO;
        self.containerLeftConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.leftAvatarContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
        self.containerLeftConstraint.active = YES;

        self.leftAvatarContainerView.hidden = YES;
        self.rightAvatarContainerView.hidden = NO;

//        self.rightAvatarWidthConstraint.constant = 50;
//        self.leftAvatarWidthConstraint.constant = 0;

        self.leftAvatarImageView.image = nil;
        [self.rightAvatarImageView setImageWithURL:[NSURL URLWithString:avatarImageUrl] placeholderImage:[UIImage imageNamed:@"icon_avatar_mine" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil]];
    } else {
        // Other's message - on the left
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_left" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];
        self.leftAvatarWidthConstraint.constant = self.avatarContainerWidth;

        // Black text on white bubble
        self.bubbleImageView.tintColor = [UIColor colorWithWhite:1 alpha:1];
        self.textContentLabel.textColor = [UIColor colorWithWhite:0 alpha:1];

        // Push the bubble to the left edge by setting the right constraint relation to >=
        self.containerRightConstraint.active = NO;
        self.containerRightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
        self.containerRightConstraint.active = YES;

        self.leftAvatarContainerView.hidden = NO;
        self.rightAvatarContainerView.hidden = YES;

//        self.rightAvatarWidthConstraint.constant = 0;
//        self.leftAvatarWidthConstraint.constant = 50;

        [self.leftAvatarImageView setImageWithURL:[NSURL URLWithString:avatarImageUrl] placeholderImage:[UIImage imageNamed:@"icon_avatar_other" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil]];
        self.rightAvatarImageView.image = nil;
    }
}

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
