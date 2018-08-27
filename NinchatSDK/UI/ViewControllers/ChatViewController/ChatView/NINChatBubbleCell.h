//
//  NINChatBubbleCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Rerepsents a chat message (in a 'bubble') in the chat view. */
@interface NINChatBubbleCell : UITableViewCell

-(void) populateWithText:(NSString*)text avatarImageUrl:(NSString*)avatarImageUrl isMine:(BOOL)isMine;

@end
