//
//  ChannelMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NINFileInfo;

/** Represents a chat message on a channel. */
@interface NINChannelMessage : NSObject

/** Message ID. */
@property (nonatomic, strong, readonly) NSString* messageID;

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign, readonly) BOOL series;

/** Name of the user who sent the message. */
@property (nonatomic, strong, readonly) NSString* senderName;

/** Message (text) content. */
@property (nonatomic, strong, readonly) NSString* textContent;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

/** User's avatar URL. */
@property (nonatomic, strong, readonly) NSString* avatarURL;

/** The sender's user ID. */
@property (nonatomic, strong, readonly) NSString* senderUserID;

/** Attachment file info. */
@property (nonatomic, strong) NINFileInfo* attachment;

/** Initializer. */
+(NINChannelMessage*) messageWithID:(NSString*)messageID textContent:(NSString*)textContent senderName:(NSString*)senderName avatarURL:(NSString*)avatarURL timestamp:(NSDate*)timestamp mine:(BOOL)mine series:(BOOL)series senderUserID:(NSString*)senderUserID;

@end
