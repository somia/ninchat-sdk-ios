//
//  ChannelMessage.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "ChannelMessage.h"

@interface ChannelMessage ()

// Writable private definitions for the properties
@property (nonatomic, assign) BOOL mine;
@property (nonatomic, strong) NSString* textContent;
@property (nonatomic, strong) NSDate* timestamp;

@end

@implementation ChannelMessage

-(NSString*) description {
    return [NSString stringWithFormat:@"textContent: %@, mine: %@, timestamp: %@", self.textContent, self.mine ? @"YES" : @"NO", self.timestamp];
}

+(ChannelMessage*) messageWithTextContent:(NSString*)textContent mine:(BOOL)mine {
    ChannelMessage* msg = [ChannelMessage new];
    msg.textContent = textContent;
    msg.mine = mine;
    msg.timestamp = [NSDate date];

    return msg;
}

@end
