//
//  ChatViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "MXRMessenger.h"

#import "ChatViewController.h"
#import "SessionManager.h"
#import "Utils.h"
#import "ChannelMessage.h"

// SEE sample: https://github.com/skensell/MXRMessenger/blob/master/Examples/Example1/Example1/ChatViewController.m

@interface ChatViewController () <MXRMessageCellFactoryDataSource, MXRMessageContentNodeDelegate, ASTableDelegate, ASTableDataSource>

/** Reference to the notifications observer that listens to new message -notifications. */
@property (nonatomic, strong) id<NSObject> messagesObserver;

/** Cell factory instantiates the chat bubble cells. */
@property (nonatomic, strong) MXRMessageCellFactory* cellFactory;

@end

@implementation ChatViewController

#pragma mark - Private methods

-(void) customizeCellFactory {
    MXRMessageCellLayoutConfiguration* layoutConfigForMe = [MXRMessageCellLayoutConfiguration rightToLeft];
    MXRMessageCellLayoutConfiguration* layoutConfigForOthers = [MXRMessageCellLayoutConfiguration leftToRight];

    MXRMessageAvatarConfiguration* avatarConfigForMe = nil;
    MXRMessageAvatarConfiguration* avatarConfigForOthers = [[MXRMessageAvatarConfiguration alloc] init];

    MXRMessageTextConfiguration* textConfigForMe = [[MXRMessageTextConfiguration alloc] initWithFont:nil textColor:[UIColor whiteColor] backgroundColor:[UIColor mxr_fbMessengerBlue]];
    MXRMessageTextConfiguration* textConfigForOthers = [[MXRMessageTextConfiguration alloc] initWithFont:nil textColor:[UIColor blackColor] backgroundColor:[UIColor mxr_bubbleLightGrayColor]];
    CGFloat maxCornerRadius = textConfigForMe.maxCornerRadius;

    MXRMessageImageConfiguration* imageConfig = [[MXRMessageImageConfiguration alloc] init];
    imageConfig.maxCornerRadius = maxCornerRadius;
    MXRMessageMediaCollectionConfiguration* mediaCollectionConfig = [[MXRMessageMediaCollectionConfiguration alloc] init];
    mediaCollectionConfig.maxCornerRadius = maxCornerRadius;

    textConfigForMe.menuItemTypes |= MXRMessageMenuItemTypeDelete;
    textConfigForOthers.menuItemTypes |= MXRMessageMenuItemTypeDelete;
    imageConfig.menuItemTypes |= MXRMessageMenuItemTypeDelete;
    imageConfig.showsUIMenuControllerOnLongTap = YES;
    CGFloat s = [UIScreen mainScreen].scale;
    imageConfig.borderWidth = s > 0 ? (1.0f/s) : 0.5f;

    MXRMessageCellConfiguration* cellConfigForMe = [[MXRMessageCellConfiguration alloc] initWithLayoutConfig:layoutConfigForMe avatarConfig:avatarConfigForMe textConfig:textConfigForMe imageConfig:imageConfig mediaCollectionConfig:mediaCollectionConfig];
    MXRMessageCellConfiguration* cellConfigForOthers = [[MXRMessageCellConfiguration alloc] initWithLayoutConfig:layoutConfigForOthers avatarConfig:avatarConfigForOthers textConfig:textConfigForOthers imageConfig:imageConfig mediaCollectionConfig:mediaCollectionConfig];

    self.cellFactory = [[MXRMessageCellFactory alloc] initWithCellConfigForMe:cellConfigForMe cellConfigForOthers:cellConfigForOthers];
    self.cellFactory.dataSource = self;
    self.cellFactory.contentNodeDelegate = self;
//    self.cellFactory.mediaCollectionDelegate = self;
}

-(void) sendButtonPressed:(id)sender {
    NSString* text = [self.toolbar clearText];
    NSLog(@"text to send: %@", text);

    [self.sessionManager sendMessage:text completion:^(NSError* _Nonnull error) {
        if (error != nil) {
            //TODO show error toast? check with UX people.
            NSLog(@"TODO: message failed to send - show error message");
        }
    }];
    /*
    if (text.length == 0) return;
    Message* message = [[Message alloc] init];
    message.text = text;
    message.senderID = 0;
    message.timestamp = [NSDate date].timeIntervalSince1970;
    [self.messages insertObject:message atIndex:0];
    [self.cellFactory updateTableNode:self.node.tableNode animated:YES withInsertions:@[[NSIndexPath indexPathForRow:0 inSection:0]] deletions:nil reloads:nil completion:nil];
     */
}

#pragma mark - From MXMessageCellFactoryDataSource

- (BOOL)cellFactory:(MXRMessageCellFactory *)cellFactory isMessageFromMeAtRow:(NSInteger)row {
    return self.sessionManager.channelMessages[row].mine;
}

- (NSURL *)cellFactory:(MXRMessageCellFactory *)cellFactory avatarURLAtRow:(NSInteger)row {
   // return [self cellFactory:cellFactory isMessageFromMeAtRow:row] ? nil : self.otherPersonsAvatar;
    //TODO get the avatar from the message
    return nil;
}

- (NSTimeInterval)cellFactory:(MXRMessageCellFactory *)cellFactory timeIntervalSince1970AtRow:(NSInteger)row {
    return [self.sessionManager.channelMessages[row].timestamp timeIntervalSince1970];
}

#pragma mark - MXRMessageContentNodeDelegate

- (void)messageContentNode:(MXRMessageContentNode *)node didTapMenuItemWithType:(MXRMessageMenuItemTypes)menuItemType {
//    if (menuItemType == MXRMessageMenuItemTypeDelete) {
//        ASDisplayNode* supernode = [node supernode];
//        if ([supernode isKindOfClass:[MXRMessageCellNode class]]) {
//            [self deleteCellNode:(MXRMessageCellNode*)supernode];
//        }
//    }
}

- (void)messageContentNode:(MXRMessageContentNode *)node didSingleTap:(id)sender {
//    if (![node.supernode isKindOfClass:[MXRMessageCellNode class]]) return;
//    MXRMessageCellNode* cellNode = (MXRMessageCellNode*)node.supernode;
//    if ([node isKindOfClass:[MXRMessageImageNode class]]) {
//        // present a media viewer
//        NSLog(@"Single tapped an image");
//        return;
//    } else if ([node isKindOfClass:[MXRMessageTextNode class]]) {
//        NSLog(@"Single tapped text");
//        [self.cellFactory toggleDateHeaderNodeVisibilityForCellNode:cellNode];
//    }
}

- (void)messageContentNode:(MXRMessageContentNode*)node didTapURL:(NSURL*)url {
    NSLog(@"Tapped URL: %@", url);
}

- (void)messageContentNode:(MXRMessageContentNode*)node didLongTapURL:(NSURL*)url {
    NSLog(@"Long-Tapped URL: %@", url);
}

#pragma mark - From ASTableDelegate

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissKeyboard];
    [tableNode deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - From ASTableDataSource

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section {
    return self.sessionManager.channelMessages.count;
}

-(ASCellNodeBlock) tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    Message* message = self.messages[indexPath.row];
    if (message.media.count > 1) {
        return [self.cellFactory cellNodeBlockWithMedia:message.media tableNode:tableNode row:indexPath.row];
    } else if (message.media.count == 1) {
        MessageMedium* medium = message.media.firstObject;
        return [self.cellFactory cellNodeBlockWithImageURL:medium.photoURL showsPlayButton:(medium.videoURL != nil) tableNode:tableNode row:indexPath.row];
    } else {
        return [self.cellFactory cellNodeBlockWithText:message.text tableNode:tableNode row:indexPath.row];
    }
    */
    ChannelMessage* msg = self.sessionManager.channelMessages[indexPath.row];

    return [self.cellFactory cellNodeBlockWithText:msg.textContent tableNode:tableNode row:indexPath.row];
}

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
/*
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.sessionManager sendMessage:@"Ninchat iOS SDK says hi" completion:^(NSError* error) {
            if (error != nil) {
                NSLog(@"Error sending message: %@", error);
                return;
            }

            NSLog(@"Message sent.");
        }];
    });
*/
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        // Insert the new message chat bubble as the newest entry
        [self.cellFactory updateTableNode:self.node.tableNode animated:YES withInsertions:@[[NSIndexPath indexPathForRow:0 inSection:0]] deletions:nil reloads:nil completion:nil];

        return NO;
    });
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
}

-(void) viewDidLoad {
    [super viewDidLoad];

}

-(instancetype) init {
    MXRMessengerInputToolbar* toolbar = [[MXRMessengerInputToolbar alloc] initWithFont:[UIFont systemFontOfSize:16.0f] placeholder:@"Type a message" tintColor:[UIColor mxr_fbMessengerBlue]];
    self = [super initWithToolbar:toolbar];
    if (self) {
        // add extra buttons to toolbar
//        MXRMessengerIconButtonNode* addPhotosBarButtonButtonNode = [MXRMessengerIconButtonNode buttonWithIcon:[[MXRMessengerPlusIconNode alloc] init] matchingToolbar:self.toolbar];
//        [addPhotosBarButtonButtonNode addTarget:self action:@selector(tapAddPhotos:) forControlEvents:ASControlNodeEventTouchUpInside];
//        self.toolbar.leftButtonsNode = addPhotosBarButtonButtonNode;
        [self.toolbar.defaultSendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:ASControlNodeEventTouchUpInside];

        // delegate must be self for interactive keyboard, datasource can be whatever
        self.node.tableNode.delegate = self;
        self.node.tableNode.dataSource = self;
        [self customizeCellFactory];
    }

    return self;
}

@end
