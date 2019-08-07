//
//  ChannelMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChannelMessage.h"

@class NINFileInfo;
@class NINChannelUser;

/** Represents a chat message on a channel. */
@interface NINTextMessage : NSObject<NINChannelMessage>

/** Message (text) content. */
@property (nonatomic, strong, readonly) NSString* textContent;

/** Attachment file info. */
@property (nonatomic, strong, readonly) NINFileInfo* attachment;

@property (nonatomic, assign) BOOL series;

/** Initializer. */
+(NINTextMessage*) messageWithID:(NSString*)messageID textContent:(NSString*)textContent sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine attachment:(NINFileInfo*)attachment;

@end
