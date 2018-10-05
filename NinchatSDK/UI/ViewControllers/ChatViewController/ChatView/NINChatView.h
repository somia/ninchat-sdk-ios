//
//  NINChatView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINChatMessage.h"
#import "NINPublicTypes.h"

@class NINChatView;
@class NINFileInfo;

/** Data source for the chat view. */
@protocol NINChatViewDataSource

/** How many messages there are. */
-(NSInteger) numberOfMessagesForChatView:(NINChatView*)chatView;

/** Returns the chat message at given index. */
-(id<NINChatMessage>) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index;

@end

/** Delegate for the chat view. */
@protocol NINChatViewDelegate

/** An image in a cell was selected (tapped). */
-(void) chatView:(NINChatView*)chatView imageSelected:(UIImage*)image forAttachment:(NINFileInfo*)attachment;

/** "Close Chat" button was pressed inside the chat view; the used requests closing the chat SDK. */
-(void) closeChatRequestedByChatView:(NINChatView*)chatView;

@end

@interface NINChatView : UIView

/** My data source. */
@property (nonatomic, weak) id<NINChatViewDataSource> dataSource;

/** My delegate. */
@property (nonatomic, weak) id<NINChatViewDelegate> delegate;

/** The image asset overrides as map. Only contains items used by chat view. */
@property (nonatomic, strong) NSDictionary<NINImageAssetKey,UIImage*>* imageAssets;

/** A new message was added at the bottom of the list (index = 0). Updates the view. */
-(void) newMessageWasAdded;

/** A message was removed from given index. */
-(void) messageWasRemovedAtIndex:(NSInteger)index;

@end

/** Storyboard/xib-embeddable subclass of NINChatView */
@interface NINEmbeddableChatView : NINChatView

@end
