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

/** Data source for the chat view. */
@protocol NINChatViewDataSource

/** How many messages there are. */
-(NSInteger) numberOfMessagesForChatView:(NINChatView*)chatView;

/** Returns the chat message at given index. */
-(NINChannelMessage*) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index;

@end

/** Delegate for the chat view. */
@protocol NINChatViewDelegate

/** An image in a cell was selected (tapped). */
-(void) chatView:(NINChatView*)chatView imageSelected:(UIImage*)image forAttachment:(NINFileInfo*)attachment;

@end

@interface NINChatView : UIView

/** My data source. */
@property (nonatomic, weak) id<NINChatViewDataSource> dataSource;

/** My delegate. */
@property (nonatomic, weak) id<NINChatViewDelegate> delegate;

/** A new message was added at the bottom of the list (index = 0). Updates the view. */
-(void) newMessageWasAdded;

@end

/** Storyboard/xib-embeddable subclass of NINChatView */
@interface NINEmbeddableChatView : NINChatView

@end
