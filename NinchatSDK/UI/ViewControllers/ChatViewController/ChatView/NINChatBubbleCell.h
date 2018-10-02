//
//  NINChatBubbleCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@class NINChannelMessage;
@class NINUserTypingMessage;
@class NINFileInfo;
@class NINVideoThumbnailManager;

typedef void (^imagePressedCallback)(NINFileInfo* attachment, UIImage* image);

/** Rerepsents a chat message (in a 'bubble') in the chat view. */
@interface NINChatBubbleCell : UITableViewCell

@property (nonatomic, strong) NINVideoThumbnailManager* videoThumbnailManager;
@property (nonatomic, copy) imagePressedCallback imagePressedCallback;
@property (nonatomic, copy) emptyBlock cellConstraintsUpdatedCallback;

-(void) populateWithChannelMessage:(NINChannelMessage*)message;
-(void) populateWithUserTypingMessage:(NINUserTypingMessage*)message typingIcon:(UIImage*)typingIcon;

@end
