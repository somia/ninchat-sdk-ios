//
//  NINChatMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NINChannelUser;

/** Describes a message shown in the chat view UI. */
@protocol NINChatMessage <NSObject>

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

@end

/** Represents a chat message on a channel. */
@protocol NINChannelMessage <NINChatMessage>

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign) BOOL series;

/** The message sender. */
@property (nonatomic, strong, readonly) NINChannelUser* sender;

/** Message identifier. */
@property (nonatomic, strong, readonly) NSString* messageID;

@end