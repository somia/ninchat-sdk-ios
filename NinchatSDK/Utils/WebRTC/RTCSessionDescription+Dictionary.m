//
//  RTCSessionDescription+JSON.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCSessionDescription+Dictionary.h"

@implementation RTCSessionDescription (Dictionary)

-(NSDictionary*) dictionary {
    return @{@"type": @(self.type), @"sdp": self.description};
}

+(RTCSessionDescription*) fromDictionary:(NSDictionary*)dictionary {
    return [[RTCSessionDescription alloc] initWithType:[dictionary[@"type"] intValue] sdp:dictionary[@"sdp"]];
}

@end
