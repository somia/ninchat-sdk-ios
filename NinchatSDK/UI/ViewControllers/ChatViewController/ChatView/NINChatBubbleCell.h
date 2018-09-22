//
//  NINChatBubbleCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINChannelMessage;
@class NINFileInfo;

typedef void (^imagePressedCallback)(NINFileInfo* attachment, UIImage* image);

/** Rerepsents a chat message (in a 'bubble') in the chat view. */
@interface NINChatBubbleCell : UITableViewCell

@property (nonatomic, copy) imagePressedCallback imagePressedCallback;

-(void) populateWithMessage:(NINChannelMessage*)message;

@end
