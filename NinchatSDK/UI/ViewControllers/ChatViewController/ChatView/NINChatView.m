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

@interface NINChatView () <UITableViewDelegate, UITableViewDataSource> {
    NSArray<NSIndexPath*>* _zeroIndexPathArray;
    NINVideoThumbnailManager* _videoThumbnailManager;
}

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@end

@implementation NINChatView

#pragma mark - Public methods

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
        [cell populateWithChannelMessage:message imageAssets:self.imageAssets];
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
        [cell populateWithUserTypingMessage:message imageAssets:self.imageAssets];
        return cell;
    } else if ([message isKindOfClass:NINChatMetaMessage.class]) {
        NINChatMetaCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatMetaCell" forIndexPath:indexPath];

        [cell populateWithMessage:message];
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
