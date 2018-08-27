//
//  NINChatBubbleCell.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatBubbleCell.h"
#import "NINUtils.h"

@interface NINChatBubbleCell ()

// Width constraint for the left avatar area; used to hide the left avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* leftAvatarWidthConstraint;

// Width constraint for the right avatar area; used to hide the right avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* rightAvatarWidthConstraint;

// The chat bubble graphic
@property (nonatomic, strong) IBOutlet UIImageView* bubbleImageView;

// The left avatar image
@property (nonatomic, strong) IBOutlet UIImageView* leftAvatarImageView;

// The right avatar image
@property (nonatomic, strong) IBOutlet UIImageView* rightAvatarImageView;

// The text container label
@property (nonatomic, strong) IBOutlet UILabel* textContentLabel;

// Original width of the avatar image containers
@property (nonatomic, assign) CGFloat avatarContainerWidth;

@end

@implementation NINChatBubbleCell

-(void) populateWithText:(NSString*)text avatarImageUrl:(NSString*)avatarImageUrl isMine:(BOOL)isMine {
    self.textContentLabel.text = text;

    //TODO do ever need a right side avatar?
    self.rightAvatarWidthConstraint.constant = 0;

    if (isMine) {
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_right" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];
        self.leftAvatarWidthConstraint.constant = 0;
        //TODO enable
//        self.leftAvatarImageView.image = nil;
    } else {
        self.bubbleImageView.image = [UIImage imageNamed:@"chat_bubble_left" inBundle:findResourceBundle(self.class) compatibleWithTraitCollection:nil];
        self.leftAvatarWidthConstraint.constant = self.avatarContainerWidth;
        //TODO set left avatar image from the URL - use a image cache. AFNetworking?
    }
}

-(void) awakeFromNib {
    [super awakeFromNib];

    self.avatarContainerWidth = self.leftAvatarWidthConstraint.constant;
}

@end
