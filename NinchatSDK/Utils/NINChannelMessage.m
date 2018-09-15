//
//  ChannelMessage.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChannelMessage.h"

@interface NINChannelMessage ()

// Writable private definitions for the properties
@property (nonatomic, assign) BOOL mine;
@property (nonatomic, assign) BOOL series;
@property (nonatomic, strong) NSString* senderName;
@property (nonatomic, strong) NSString* textContent;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSString* avatarURL;
@property (nonatomic, strong) NSString* senderUserID;

@end

@implementation NINChannelMessage

-(NSString*) description {
    return [NSString stringWithFormat:@"textContent: %@, mine: %@, series %@, timestamp: %@", self.textContent, self.mine ? @"YES" : @"NO", self.series ? @"YES" : @"NO", self.timestamp];
}

+(NINChannelMessage*) messageWithTextContent:(NSString*)textContent senderName:(NSString*)senderName avatarURL:(NSString*)avatarURL timestamp:(NSDate*)timestamp mine:(BOOL)mine series:(BOOL)series senderUserID:(NSString*)senderUserID {
    NINChannelMessage* msg = [NINChannelMessage new];

    msg.senderName = senderName;
    msg.textContent = textContent;
    msg.mine = mine;
    msg.timestamp = timestamp;
    msg.avatarURL = avatarURL;
    msg.series = series;
    msg.senderUserID = senderUserID;

    return msg;
}

@end
