//
//  ChannelMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChatMessage.h"

@class NINFileInfo;
@class NINChannelUser;

/** Represents a chat message on a channel. */
@interface NINChannelMessage : NSObject <NINChatMessage>

/** Message ID. */
@property (nonatomic, strong, readonly) NSString* messageID;

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign) BOOL series;

/** The message sender. */
@property (nonatomic, strong, readonly) NINChannelUser* sender;

/** Message (text) content. */
@property (nonatomic, strong, readonly) NSString* textContent;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

/** Attachment file info. */
@property (nonatomic, strong, readonly) NINFileInfo* attachment;

/** Initializer. */
+(NINChannelMessage*) messageWithID:(NSString*)messageID textContent:(NSString*)textContent sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine attachment:(NINFileInfo*)attachment;

@end
