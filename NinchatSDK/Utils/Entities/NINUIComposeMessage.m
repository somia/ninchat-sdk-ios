//
//  NINUIComposeMessage.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 08/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINUIComposeMessage.h"

@interface NINUIComposeOption ()

// Writable private definitions for the properties
@property (nonatomic, strong) NSString* label;
@property (nonatomic, strong) NSString* value;

@end

@implementation NINUIComposeOption

+(NINUIComposeOption*) optionWithValue:(NSString*)value label:(NSString*)label {
    NINUIComposeOption* option = [NINUIComposeOption new];
    option.value = value;
    option.label = label;
    return option;
}

@end

@interface NINUIComposeMessage ()

// Writable private definitions for the properties
@property (nonatomic, strong) NSString* messageID;
@property (nonatomic, assign) BOOL mine;
@property (nonatomic, strong) NINChannelUser* sender;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSString* className;
@property (nonatomic, strong) NSString* element;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* label;
@property (nonatomic, strong) NSArray<NSString*>* options;

@end

@implementation NINUIComposeMessage

+(NINUIComposeMessage*) messageWithID:(NSString*)messageID sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine className:(NSString*)className element:(NSString*)element uid:(NSString*)uid name:(NSString*)name label:(NSString*)label options:(NSArray<NSString*>*)options {
    
    NINUIComposeMessage* msg = [NINUIComposeMessage new];
    msg.messageID = messageID;
    msg.sender = sender;
    msg.timestamp = timestamp;
    msg.mine = mine;
    msg.series = NO;
    msg.className = className;
    msg.element = element;
    msg.name = name;
    msg.label = label;
    msg.options = options;

    return msg;
}

@end
