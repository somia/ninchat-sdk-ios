//
//  NINChatView.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatView.h"
#import "NINUtils.h"
#import "NINChannelMessage.h"
#import "NINChatMetaMessage.h"
#import "NINUserTypingMessage.h"
#import "NINChatBubbleCell.h"
#import "NINChatMetaCell.h"
#import "NINVideoThumbnailManager.h"
#import "NINChatSession+Internal.h"

@interface NINChatView () <UITableViewDelegate, UITableViewDataSource> {
    NSArray<NSIndexPath*>* _zeroIndexPathArray;
    NINVideoThumbnailManager* _videoThumbnailManager;
}

@property (nonatomic, strong) IBOutlet UITableView* tableView;

/**
 * The image asset overrides as map. Only contains items used by chat view.
 * These are cached in this fashion to avoid looking them up from the chat delegate
 * every time a cell needs updating.
 */
@property (nonatomic, strong) NSDictionary<NINImageAssetKey,UIImage*>* imageAssets;

/**
 * The color asset overrides as map. Only contains items used by chat view.
 * These are cached in this fashion to avoid looking them up from the chat delegate
 * every time a cell needs updating.
 */
@property (nonatomic, strong) NSDictionary<NINColorAssetKey,UIColor*>* colorAssets;

@end

@implementation NINChatView

#pragma mark - Private methods

-(NSDictionary<NINImageAssetKey, UIImage*>*) createImageAssetDictionary {
    NSCAssert(self.session != nil, @"Session cannot be nil");

    // User typing indicator
    UIImage* userTypingIcon = [self.session overrideImageAssetForKey:NINImageAssetKeyChatWritingIndicator];

    if (userTypingIcon == nil) {
        NSMutableArray* frames = [NSMutableArray arrayWithCapacity:25];
        for (NSInteger i = 1; i <= 23; i++) {
            NSString* imageName = [NSString stringWithFormat:@"icon_writing_%02ld", (long)i];
            [frames addObject:[UIImage imageNamed:imageName inBundle:findResourceBundle() compatibleWithTraitCollection:nil]];
        }
        userTypingIcon = [UIImage animatedImageWithImages:frames duration:1.0];
    }

    // Left side bubble
    UIImage* leftSideBubble = [self.session overrideImageAssetForKey:NINImageAssetKeyChatBubbleLeft];
    if (leftSideBubble == nil) {
        leftSideBubble = [UIImage imageNamed:@"chat_bubble_left" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Left side bubble (series)
    UIImage* leftSideBubbleSeries = [self.session overrideImageAssetForKey:NINImageAssetKeyChatBubbleLeftRepeated];
    if (leftSideBubbleSeries == nil) {
        leftSideBubbleSeries = [UIImage imageNamed:@"chat_bubble_left_series" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Right side bubble
    UIImage* rightSideBubble = [self.session overrideImageAssetForKey:NINImageAssetKeyChatBubbleRight];
    if (rightSideBubble == nil) {
        rightSideBubble = [UIImage imageNamed:@"chat_bubble_right" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Right side bubble (series)
    UIImage* rightSideBubbleSeries = [self.session overrideImageAssetForKey:NINImageAssetKeyChatBubbleRightRepeated];
    if (rightSideBubbleSeries == nil) {
        rightSideBubbleSeries = [UIImage imageNamed:@"chat_bubble_right_series" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Left side avatar
    UIImage* leftSideAvatar = [self.session overrideImageAssetForKey:NINImageAssetKeyChatAvatarLeft];
    if (leftSideAvatar == nil) {
        leftSideAvatar = [UIImage imageNamed:@"icon_avatar_other" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Right side avatar
    UIImage* rightSideAvatar = [self.session overrideImageAssetForKey:NINImageAssetKeyChatAvatarRight];
    if (rightSideAvatar == nil) {
        rightSideAvatar = [UIImage imageNamed:@"icon_avatar_mine" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    // Play video icon
    UIImage* playVideoIcon = [self.session overrideImageAssetForKey:NINImageAssetKeyChatPlayVideo];
    if (playVideoIcon == nil) {
        playVideoIcon = [UIImage imageNamed:@"icon_play" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }

    return @{NINImageAssetKeyChatWritingIndicator: userTypingIcon,
             NINImageAssetKeyChatBubbleLeft: leftSideBubble,
             NINImageAssetKeyChatBubbleLeftRepeated: leftSideBubbleSeries,
             NINImageAssetKeyChatBubbleRight: rightSideBubble,
             NINImageAssetKeyChatBubbleRightRepeated: rightSideBubbleSeries,
             NINImageAssetKeyChatAvatarLeft: leftSideAvatar,
             NINImageAssetKeyChatAvatarRight: rightSideAvatar,
             NINImageAssetKeyChatPlayVideo: playVideoIcon};
}

-(NSDictionary<NINColorAssetKey, UIColor*>*) createColorAssetDictionary {
    NSCAssert(self.session != nil, @"Session cannot be nil");

    NSArray* relatedKeys = @[NINColorAssetKeyInfoText, NINColorAssetKeyChatName, NINColorAssetKeyChatTimestamp, NINColorAssetKeyChatBubbleLeftText, NINColorAssetKeyChatBubbleRightText, NINColorAssetKeyChatBubbleLeftLink, NINColorAssetKeyChatBubbleRightLink];

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    for (NINColorAssetKey key in relatedKeys) {
        UIColor* color = [self.session overrideColorAssetForKey:key];
        if (color != nil) {
            dict[key] = color;
        }
    }

    return dict;
}

#pragma mark - Public methods

-(void) setSession:(NINChatSession*)session {
    _session = session;

    self.imageAssets = [self createImageAssetDictionary];
    self.colorAssets = [self createColorAssetDictionary];
}

-(void) newMessageWasAdded {
    [self.tableView insertRowsAtIndexPaths:_zeroIndexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void) messageWasRemovedAtIndex:(NSInteger)index {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - From UITableViewDelegate

-(nonnull UITableViewCell*)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    __weak typeof(self) weakSelf = self;
    id<NINChatMessage> message = [self.dataSource chatView:self messageAtIndex:indexPath.row];

    if ([message isKindOfClass:NINChannelMessage.class]) {
        NINChatBubbleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatBubbleCell" forIndexPath:indexPath];
        cell.videoThumbnailManager = _videoThumbnailManager;
        [cell populateWithChannelMessage:message imageAssets:self.imageAssets colorAssets:self.colorAssets];
        cell.imagePressedCallback = ^(NINFileInfo* attachment, UIImage *image) {
            [weakSelf.delegate chatView:weakSelf imageSelected:image forAttachment:attachment];
        };
        cell.cellConstraintsUpdatedCallback = ^{
            [UIView animateWithDuration:0.3 animations:^{
                [weakSelf.tableView beginUpdates];
                [weakSelf.tableView endUpdates];
            }];
        };
        return cell;
    } else if ([message isKindOfClass:NINUserTypingMessage.class]) {
        NINChatBubbleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatBubbleCell" forIndexPath:indexPath];
        cell.videoThumbnailManager = nil;
        [cell populateWithUserTypingMessage:message imageAssets:self.imageAssets colorAssets:self.colorAssets];
        return cell;
    } else if ([message isKindOfClass:NINChatMetaMessage.class]) {
        NINChatMetaCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatMetaCell" forIndexPath:indexPath];

        [cell populateWithMessage:message colorAssets:self.colorAssets session:self.session];
        cell.closeChatCallback = ^{
            [weakSelf.delegate closeChatRequestedByChatView:weakSelf];
        };

        return cell;
    } else {
        NSCAssert(NO, @"Invalid message type");
        return nil;
    }
}

#pragma mark - From UITableViewDataSource

-(NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfMessagesForChatView:self];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    _videoThumbnailManager = [NINVideoThumbnailManager new];
    _zeroIndexPathArray = @[[NSIndexPath indexPathForRow:0 inSection:0]];

    NSBundle* bundle = findResourceBundle();
    NSCAssert(bundle != nil, @"Bundle not found");

    UINib* bubbleNib = [UINib nibWithNibName:@"NINChatBubbleCell" bundle:bundle];
    NSCAssert(bubbleNib != nil, @"NIB not found");
    [self.tableView registerNib:bubbleNib forCellReuseIdentifier:@"NINChatBubbleCell"];

    UINib* metaNib = [UINib nibWithNibName:@"NINChatMetaCell" bundle:bundle];
    NSCAssert(metaNib != nil, @"NIB not found");
    [self.tableView registerNib:metaNib forCellReuseIdentifier:@"NINChatMetaCell"];

    // Rotate the table view 180 degrees; we will use it upside down
    self.tableView.transform = CGAffineTransformMakeRotation(M_PI);
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end

#pragma mark - NINEmbeddableNINChatView

@implementation NINEmbeddableChatView

// Loads the NINNavigationBar view from its xib
-(NINChatView*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINChatView" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINChatView class]], @"Invalid class resource");
    
    return (NINChatView*)objects[0];
}

// Substitutes the original view content (eg. from Storyboard) with contents of the xib
-(id) awakeAfterUsingCoder:(NSCoder *)aDecoder {
    NINChatView* newView = [self loadViewFromNib];

    newView.frame = self.frame;
    newView.autoresizingMask = self.autoresizingMask;
    newView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints;

    // Not to break the layout surrounding this view, we must copy the constraints over
    // to the newly loaded view
    for (NSLayoutConstraint* constraint in self.constraints) {
        id firstItem = (constraint.firstItem == self) ? newView : constraint.firstItem;
        id secondItem = (constraint.secondItem == self) ? newView : constraint.secondItem;

        [newView addConstraint:[NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
    }

    return newView;
}

@end
