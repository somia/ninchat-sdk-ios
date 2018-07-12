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
@property (nonatomic, strong) NSString* textContent;
@property (nonatomic, strong) NSDate* timestamp;

@end

@implementation NINChannelMessage

-(NSString*) description {
    return [NSString stringWithFormat:@"textContent: %@, mine: %@, timestamp: %@", self.textContent, self.mine ? @"YES" : @"NO", self.timestamp];
}

+(NINChannelMessage*) messageWithTextContent:(NSString*)textContent mine:(BOOL)mine {
    NINChannelMessage* msg = [NINChannelMessage new];
    msg.textContent = textContent;
    msg.mine = mine;
    msg.timestamp = [NSDate date];

    return msg;
}

@end
