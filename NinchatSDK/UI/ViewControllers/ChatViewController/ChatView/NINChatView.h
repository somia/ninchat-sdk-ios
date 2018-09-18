//
//  NINChatView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINChatView;
@class NINChannelMessage;
@class NINFileInfo;

/*
@protocol NINChatViewMessageAttachment <NSObject>

@property (nonatomic, strong, readonly) NSString* fileID;
@property (nonatomic, strong, readonly) NSString* mimeType;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, strong, readonly) NSString* url;
@property (nonatomic, strong, readonly) NSDate* urlExpiry;

@end

@protocol NINChatViewMessage <NSObject>

@property (nonatomic, strong, readonly) NSString* messageID;
@property (nonatomic, assign, readonly) BOOL mine;
@property (nonatomic, assign, readonly) BOOL series;
@property (nonatomic, strong, readonly) NSString* senderName;
@property (nonatomic, strong, readonly) NSString* textContent;
@property (nonatomic, strong, readonly) NSDate* timestamp;
@property (nonatomic, strong, readonly) NSString* avatarURL;
@property (nonatomic, strong, readonly) id<NINChatViewMessageAttachment> attachment;

@end
*/

/** Data source for the chat view. */
@protocol NINChatViewDataSource

/** How many messages there are. */
-(NSInteger) numberOfMessagesForChatView:(NINChatView*)chatView;

/** Returns the chat message at given index. */
-(NINChannelMessage*) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index;

@end


@interface NINChatView : UIView

/** My data source. */
@property (nonatomic, weak) id<NINChatViewDataSource> dataSource;

/** A new message was added at the bottom of the list (index = 0). Updates the view. */
-(void) newMessageWasAdded;

@end

/** Storyboard/xib-embeddable subclass of NINChatView */
@interface NINEmbeddableChatView : NINChatView

@end
