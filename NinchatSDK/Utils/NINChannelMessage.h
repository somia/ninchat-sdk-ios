//
//  ChannelMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Represents a chat message on a channel. */
@interface NINChannelMessage : NSObject

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/** Name of the user who sent the message. */
@property (nonatomic, strong, readonly) NSString* senderName;

/** Message (text) content. */
@property (nonatomic, strong, readonly) NSString* textContent;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

/** User's avatar URL. */
@property (nonatomic, strong, readonly) NSString* avatarURL;

/** Initializer. */
+(NINChannelMessage*) messageWithTextContent:(NSString*)textContent senderName:(NSString*)senderName avatarURL:(NSString*)avatarURL mine:(BOOL)mine;

@end
