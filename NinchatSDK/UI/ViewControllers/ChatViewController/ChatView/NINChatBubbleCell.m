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
#import "NINChannelMessage.h"
#import "NINUserTypingMessage.h"
#import "NINFileInfo.h"
#import "NINChannelUser.h"
#import "UIImageView+Ninchat.h"

@interface NINChatBubbleCell ()

// Width constraint for the left avatar area; used to hide the left avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* leftAvatarWidthConstraint;

// Width constraint for the right avatar area; used to hide the right avatar
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* rightAvatarWidthConstraint;

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

// The message's image
@property (nonatomic, strong) IBOutlet UIImageView* messageImageView;

// Constraint for binding sender name / time labels to left edge
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topLabelsLeftConstraint;

// Constraint for binding sender name / time labels to right edge
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topLabelsRightConstraint;

// Height constraint for the top labels container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topLabelsContainerHeightConstraint;

// The bubble contents container view
@property (nonatomic, strong) IBOutlet UIView* bubbleContentsContainerView;

// Left side constraint for the bubble contents container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bubbleContentsContainerLeftConstraint;

// Right side constraint for the bubble contents container
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bubbleContentsContainerRightConstraint;

// Message's image (proportional) width constraint
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* imageProportionalWidthConstraint;

// Message's image (absolute) width constraint. Used for user typing.. mode.
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* imageWidthConstraint;

// Message image's aspect ratio constraint
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* imageAspectRatioConstraint;

// Original width of the avatar image containers
@property (nonatomic, assign) CGFloat avatarContainerWidth;

// Original height for the top labels container
@property (nonatomic, assign) CGFloat topLabelsContainerHeight;

// The message this cell is representing
@property (nonatomic, strong) NINChannelMessage* message;

// Message updated -listener
@property (nonatomic, assign) id messageUpdatedListener;

// Image / video tap recognizer
@property (nonatomic, strong) UITapGestureRecognizer* imageTapRecognizer;

@end

@implementation NINChatBubbleCell

#pragma mark - Private methods

-(void) configureForMyMessageWithSeries:(BOOL)series avatarURL:(NSString*)avatarURL {
    NSString* imageName = series ? @"chat_bubble_right_series" : @"chat_bubble_right";
    self.bubbleImageView.image = [UIImage imageNamed:imageName inBundle:findResourceBundle() compatibleWithTraitCollection:nil];

    // White text on black bubble
    self.bubbleImageView.tintColor = [UIColor blackColor];
    self.textContentLabel.textColor = [UIColor whiteColor];

    // Push the top label container to the left edge by toggling the constraints
    self.topLabelsLeftConstraint.active = NO;
    self.topLabelsRightConstraint.active = YES;

    // Push the bubble to the right edge by setting the left constraint relation to >= ...
    self.bubbleContentsContainerLeftConstraint.active = NO;
    self.bubbleContentsContainerLeftConstraint = [NSLayoutConstraint constraintWithItem:self.bubbleContentsContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.leftAvatarContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    // .. and right to =
    self.bubbleContentsContainerRightConstraint.active = NO;
    self.bubbleContentsContainerRightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.bubbleContentsContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];

    // Activate both
    self.bubbleContentsContainerLeftConstraint.active = YES;
    self.bubbleContentsContainerRightConstraint.active = YES;

    self.leftAvatarContainerView.hidden = YES;
    self.rightAvatarContainerView.hidden = series;

    self.leftAvatarImageView.image = nil;
    [self.rightAvatarImageView setImageWithURL:[NSURL URLWithString:avatarURL] placeholderImage:[UIImage imageNamed:@"icon_avatar_mine" inBundle:findResourceBundle() compatibleWithTraitCollection:nil]];
}

-(void) configureForOthersMessageWithSeries:(BOOL)series avatarURL:(NSString*)avatarURL {
    NSString* imageName = series ? @"chat_bubble_left_series" : @"chat_bubble_left";
    self.bubbleImageView.image = [UIImage imageNamed:imageName inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    self.leftAvatarWidthConstraint.constant = self.avatarContainerWidth;

    // Black text on white bubble
    self.bubbleImageView.tintColor = [UIColor whiteColor];
    self.textContentLabel.textColor = [UIColor blackColor];

    // Push the top label container to the left edge by toggling the constraints
    self.topLabelsRightConstraint.active = NO;
    self.topLabelsLeftConstraint.active = YES;

    // Push the bubble to the left edge by setting the right constraint relation to >= ...
    self.bubbleContentsContainerRightConstraint.active = NO;
    self.bubbleContentsContainerRightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.bubbleContentsContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    // .. and left to =
    self.bubbleContentsContainerLeftConstraint.active = NO;
    self.bubbleContentsContainerLeftConstraint = [NSLayoutConstraint constraintWithItem:self.bubbleContentsContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.leftAvatarContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];

    // Activate both
    self.bubbleContentsContainerRightConstraint.active = YES;
    self.bubbleContentsContainerLeftConstraint.active = YES;

    self.leftAvatarContainerView.hidden = series;
    self.rightAvatarContainerView.hidden = YES;

    [self.leftAvatarImageView setImageWithURL:[NSURL URLWithString:avatarURL] placeholderImage:[UIImage imageNamed:@"icon_avatar_other" inBundle:findResourceBundle() compatibleWithTraitCollection:nil]];
    self.rightAvatarImageView.image = nil;
}

-(void) imagePressed {
    NSLog(@"Image pressed: %@", self.messageImageView.image);

    if ((self.imagePressedCallback != nil) && (self.messageImageView.image != nil)) {
        self.imagePressedCallback(self.message.attachment, self.messageImageView.image);
    }
}

-(void) setImageAspectRatio:(CGFloat)aspectRatio {
    self.imageAspectRatioConstraint.active = NO;
    self.imageAspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.messageImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.messageImageView attribute:NSLayoutAttributeWidth multiplier:aspectRatio constant:0];
    self.imageAspectRatioConstraint.active = YES;
}

-(void) updateImage {
    NINFileInfo* attachment = self.message.attachment;

    self.messageImageView.image = nil;

    if ((attachment != nil) && attachment.isImage) {
        // Load the image in message image view over HTTP or from local cache
        NSLog(@"Message has an image with URL: %@", attachment.url);
        
        [self.messageImageView setImageURL:attachment.url];

        if (self.imageTapRecognizer == nil) {
            self.imageTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed)];
            [self.messageImageView addGestureRecognizer:self.imageTapRecognizer];
        }

        // Allow the image to have a width propertional to the cell content view
        self.imageProportionalWidthConstraint.active = YES;
        self.imageWidthConstraint.active = NO;

        if (attachment.aspectRatio > 0) {
            // Set message image's aspect ratio
            [self setImageAspectRatio:(1.0 / attachment.aspectRatio)];
        }
    } else {
        // No image; clear image constraints etc so it wont affect layout
        self.imageProportionalWidthConstraint.active = NO;
        [self setImageAspectRatio:0];
        if (self.imageTapRecognizer != nil) {
            [self.messageImageView removeGestureRecognizer:self.imageTapRecognizer];
            self.imageTapRecognizer = nil;
        }
    }
}

#pragma mark - Public methods

-(void) populateWithChannelMessage:(NINChannelMessage*)message {
    self.message = message;

    self.textContentLabel.text = message.textContent;
    self.senderNameLabel.text = message.sender.displayName;
    if (self.senderNameLabel.text.length < 1) {
        self.senderNameLabel.text = @"Guest";
    }

    NSCAssert(self.topLabelsLeftConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsRightConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsContainerHeightConstraint != nil, @"Cannot be nil");

    self.topLabelsContainerHeightConstraint.constant = message.series ? 0 : self.topLabelsContainerHeight;

    if (message.mine) {
        // Visitor's (= phone user) message - on the right
        [self configureForMyMessageWithSeries:message.series avatarURL:message.sender.iconURL];
    } else {
        // Other's message - on the left
        [self configureForOthersMessageWithSeries:message.series avatarURL:message.sender.iconURL];
    }

    // Make Image view background match the bubble color
    self.messageImageView.backgroundColor = self.bubbleImageView.tintColor;

    // Update the message image, if any
    [self updateImage];
}

-(void) populateWithUserTypingMessage:(NINUserTypingMessage*)message typingIcon:(UIImage*)typingIcon {
    NSCAssert(typingIcon != nil, @"Typing icon cannot be nil!");

    self.senderNameLabel.text = message.user.displayName;
    self.textContentLabel.text = nil;
    self.messageImageView.image = typingIcon;

    self.topLabelsContainerHeightConstraint.constant = self.topLabelsContainerHeight;

    [self configureForOthersMessageWithSeries:NO avatarURL:message.user.iconURL];

    // Make Image view background match the bubble color
    self.messageImageView.backgroundColor = self.bubbleImageView.tintColor;

    // Allow the image to have absolute width
    self.imageProportionalWidthConstraint.active = NO;
    self.imageWidthConstraint.active = YES;

    // Set the image aspect ratio to match the animation frames' size 40x20
    [self setImageAspectRatio:0.5];
}

#pragma mark - Lifecycle etc.

-(void) dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self.messageUpdatedListener];
}

-(void) awakeFromNib {
    [super awakeFromNib];

    self.avatarContainerWidth = self.leftAvatarWidthConstraint.constant;
    self.topLabelsContainerHeight = self.topLabelsContainerHeightConstraint.constant;

    // Make the avatar image views circles
    self.leftAvatarImageView.layer.cornerRadius = self.leftAvatarImageView.bounds.size.height / 2;
    self.leftAvatarImageView.layer.masksToBounds = YES;
    self.rightAvatarImageView.layer.cornerRadius = self.rightAvatarImageView.bounds.size.height / 2;
    self.rightAvatarImageView.layer.masksToBounds = YES;

    // Rotate the cell 180 degrees; we will use the table view upside down
    self.transform = CGAffineTransformMakeRotation(M_PI);

    // The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = UIScreen.mainScreen.scale;
}

@end
