//
//  ChannelMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Represents a chat message on a channel. */
@interface ChannelMessage : NSObject

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/** Message (text) content. */
@property (nonatomic, strong, readonly) NSString* textContent;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

/** Initializer. */
+(ChannelMessage*) messageWithTextContent:(NSString*)textContent mine:(BOOL)mine;

@end
