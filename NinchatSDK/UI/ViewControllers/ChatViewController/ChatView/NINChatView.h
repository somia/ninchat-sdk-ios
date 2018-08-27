//
//  NINChatView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINChatView;

/** Data source for the chat view. */
@protocol NINChatViewDataSource

/** How many messages there are. */
-(NSInteger) numberOfMessagesForChatView:(NINChatView*)chatView;

/** Must return YES if the message at given index is 'from me'. */
-(BOOL) chatView:(NINChatView*)chatView isMessageFromMeAtIndex:(NSInteger)index;

/** Must return the text content of the message at given index. */
-(NSString*) chatView:(NINChatView*)chatView messageTextAtIndex:(NSInteger)index;

/** Must return the avatar image URL of the message at given index. */
-(NSString*) chatView:(NINChatView*)chatView avatarURLAtIndex:(NSInteger)index;

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
