//
//  ChannelMessage.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChannelMessage.h"
#import "NINFileInfo.h"
#import "NINChannelUser.h"

@interface NINChannelMessage ()

// Writable private definitions for the properties
@property (nonatomic, strong) NSString* messageID;
@property (nonatomic, assign) BOOL mine;
@property (nonatomic, strong) NINChannelUser* sender;
@property (nonatomic, strong) NSString* textContent;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NINFileInfo* attachment;

@end

@implementation NINChannelMessage

-(NSString*) description {
    return [NSString stringWithFormat:@"NINChannelMessage textContent: %@, mine: %@, series %@, timestamp: %@", self.textContent, self.mine ? @"YES" : @"NO", self.series ? @"YES" : @"NO", self.timestamp];
}

+(NINChannelMessage*) messageWithID:(NSString*)messageID textContent:(NSString*)textContent sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine attachment:(NINFileInfo*)attachment {

    NINChannelMessage* msg = [NINChannelMessage new];
    msg.messageID = messageID;
//    msg.senderName = senderName;
    msg.textContent = textContent;
    msg.sender = sender;
    msg.mine = mine;
    msg.timestamp = timestamp;
//    msg.avatarURL = avatarURL;
//    msg.senderUserID = senderUserID;
    msg.attachment = attachment;
    msg.series = NO;

    return msg;
}

@end
