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
#import "UITextView+Ninchat.h"
#import "NINVideoThumbnailManager.h"
#import "NINToast.h"

@interface NINChatBubbleCell () <UITextViewDelegate>

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

// Bubble message text view
@property (nonatomic, strong) IBOutlet UITextView* messageTextView;

// The message's image
@property (nonatomic, strong) IBOutlet UIImageView* messageImageView;

// Video play image
@property (nonatomic, strong) IBOutlet UIImageView* videoPlayImageView;

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

// Height constraint for the message text to set it to 0 for when there is no text.
@property (nonatomic, strong) NSLayoutConstraint* textHeightConstraint;

// Message image's aspect ratio constraint
@property (nonatomic, strong) NSLayoutConstraint* imageAspectRatioConstraint;

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
    self.messageTextView.textColor = [UIColor whiteColor];

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
    self.messageTextView.textColor = [UIColor blackColor];

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
    if (self.imagePressedCallback != nil) {
        if (self.message.attachment.isVideo) {
            self.imagePressedCallback(self.message.attachment, nil);
        } else if (self.message.attachment.isImage && (self.messageImageView.image != nil)) {
            self.imagePressedCallback(self.message.attachment, self.messageImageView.image);
        }
    }
}

-(void) setImageAspectRatio:(CGFloat)aspectRatio {
    NSLog(@"Setting image view aspect ratio to %f", aspectRatio);

    self.imageAspectRatioConstraint.active = NO;
    self.imageAspectRatioConstraint = [self.messageImageView.heightAnchor constraintEqualToAnchor:self.messageImageView.widthAnchor multiplier:aspectRatio];
    self.imageAspectRatioConstraint.active = YES;
}

-(void) updateImage {
    NSCAssert(self.message.attachment != nil, @"Must have attachment here");
    NSCAssert(self.message.attachment.isImageOrVideo, @"Attachment must be image or video");
    NSCAssert(self.videoThumbnailManager != nil, @"Must have videoThumbnailManager");
    
    NINFileInfo* attachment = self.message.attachment;
    self.messageImageView.image = nil;

    if (attachment.isImage) {
        // Load the image in message image view over HTTP or from local cache
        [self.messageImageView setImageURL:attachment.url];
    } else {
        // For video we must fetch the thumbnail image
        __weak typeof(self) weakSelf = self;
        NSLog(@"Extracting video thumbnail.");
        [self.videoThumbnailManager extractThumbnail:attachment.url completion:^(NSError * _Nullable error, BOOL fromCache, UIImage * _Nullable thumbnail) {
            if (error != nil) {
                //TODO localize error msg
                [NINToast showWithMessage:@"Failed to get video thumbnail" callback:nil];
            } else {
                attachment.aspectRatio = thumbnail.size.width / thumbnail.size.height;

                // Update constraints to match new thumbnail image size
                weakSelf.messageImageView.image = thumbnail;
                [weakSelf setImageAspectRatio:thumbnail.size.height / thumbnail.size.width];
                [weakSelf.contentView setNeedsLayout];//TODO needed?

                if (fromCache) {
                    // Animate the thumbnail in
                    weakSelf.messageImageView.alpha = 0;
                    [UIView animateWithDuration:0.3 animations:^{
                        weakSelf.messageImageView.alpha = 1;
                    } completion:^(BOOL finished) {
                    }];
                }
            }
        }];
    }

    if (self.imageTapRecognizer == nil) {
        self.imageTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed)];
        [self.messageImageView addGestureRecognizer:self.imageTapRecognizer];
    }

    // Allow the image to have a width propertional to the cell content view
    self.imageWidthConstraint.active = NO;
    self.imageProportionalWidthConstraint.active = YES;

    if (attachment.aspectRatio > 0) {
        // Set message image's aspect ratio
        [self setImageAspectRatio:(1.0 / attachment.aspectRatio)];
    }

    [self.contentView setNeedsLayout];//TODO needed?

    NSLog(@"updateImage returning.");
}

#pragma mark - Public methods

-(void) populateWithChannelMessage:(NINChannelMessage*)message {
    NSCAssert(self.topLabelsLeftConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsRightConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsContainerHeightConstraint != nil, @"Cannot be nil");
    NSCAssert(self.imageProportionalWidthConstraint != nil, @"Cannot be nil");
    NSCAssert(self.imageWidthConstraint != nil, @"Cannot be nil");
//    NSCAssert(self.textHeightConstraint != nil, @"Cannot be nil");

    self.message = message;
    NINFileInfo* attachment = message.attachment;

    self.videoPlayImageView.hidden = !message.attachment.isVideo;

    if (self.message.attachment.isPDF) {
        [self.messageTextView setFormattedText:[NSString stringWithFormat:@"<a href=\"%@\">%@</a>", attachment.url, attachment.name]];
    } else {
        self.messageTextView.text = message.textContent;
        if (message.textContent == nil) {
            //TODO try to make this an IBOutlet and just activate/deactive
            if (self.textHeightConstraint == nil) {
                self.textHeightConstraint = [self.messageTextView.heightAnchor constraintEqualToConstant:0];
                self.textHeightConstraint.priority = 999;
                self.textHeightConstraint.active = YES;
            } else {
                self.textHeightConstraint.active = NO;
                self.textHeightConstraint = nil;
            }
        }
    }
    self.senderNameLabel.text = message.sender.displayName;
    if (self.senderNameLabel.text.length < 1) {
        self.senderNameLabel.text = @"Guest";
    }

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
    if (attachment == nil) {
        // No image; clear image constraints etc so it wont affect layout
        self.imageProportionalWidthConstraint.active = NO;
        self.imageAspectRatioConstraint.active = NO;
        self.imageAspectRatioConstraint = nil;
        self.imageWidthConstraint.active = NO;
        self.messageImageView.image = nil;

        if (self.imageTapRecognizer != nil) {
            [self.messageImageView removeGestureRecognizer:self.imageTapRecognizer];
            self.imageTapRecognizer = nil;
        }
    } else if (attachment.isImage || attachment.isVideo) {
        __weak typeof(self) weakSelf = self;

        [attachment updateInfoWithCompletionCallback:^(NSError* error) {
            [weakSelf updateImage];
        }];
    }

    NSLog(@"populateWithChannelMessage: returning.");
}

-(void) populateWithUserTypingMessage:(NINUserTypingMessage*)message typingIcon:(UIImage*)typingIcon {
    NSCAssert(typingIcon != nil, @"Typing icon cannot be nil!");
    NSCAssert(self.topLabelsLeftConstraint != nil, @"Cannot be nil");
    NSCAssert(self.topLabelsRightConstraint != nil, @"Cannot be nil");
    NSCAssert(self.imageProportionalWidthConstraint != nil, @"Cannot be nil");
    NSCAssert(self.imageWidthConstraint != nil, @"Cannot be nil");

    self.senderNameLabel.text = message.user.displayName;
    self.messageTextView.text = nil;
    self.messageImageView.image = typingIcon;
    self.videoPlayImageView.hidden = YES;

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

#pragma mark - From UITextViewDelegate

// Pre-iOS 10
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
}

// iOS 10 and up
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0)) {
    return YES;
}

#pragma mark - Lifecycle etc.

-(void) dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self.messageUpdatedListener];
}

-(void) awakeFromNib {
    [super awakeFromNib];

    self.avatarContainerWidth = self.leftAvatarWidthConstraint.constant;
    self.topLabelsContainerHeight = self.topLabelsContainerHeightConstraint.constant;

    self.messageTextView.delegate = self;
    
    // Make the avatar image views circles
    self.leftAvatarImageView.layer.cornerRadius = self.leftAvatarImageView.bounds.size.height / 2;
    self.leftAvatarImageView.layer.masksToBounds = YES;
    self.rightAvatarImageView.layer.cornerRadius = self.rightAvatarImageView.bounds.size.height / 2;
    self.rightAvatarImageView.layer.masksToBounds = YES;

    // Rotate the cell 180 degrees; we will use the table view upside down
    self.transform = CGAffineTransformMakeRotation(M_PI);

    // Workaround for https://openradar.appspot.com/18448072
    UIImage* image = self.videoPlayImageView.image;
    self.videoPlayImageView.image = nil;
    self.videoPlayImageView.image = image;

    // The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = UIScreen.mainScreen.scale;
}

@end
