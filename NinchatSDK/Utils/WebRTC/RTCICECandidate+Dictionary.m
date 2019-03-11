//
//  RTCICECandidate+Dictionary.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCICECandidate+Dictionary.h"

@implementation RTCIceCandidate (Dictionary)

-(NSDictionary*) dictionary {
    return @{@"label": @(self.sdpMLineIndex), @"id": self.sdpMid, @"candidate": self.sdp};
}

+(RTCIceCandidate*) fromDictionary:(NSDictionary*)dictionary {
//    return [[RTCIceCandidate alloc] initWithMid:dictionary[@"id"] index:[dictionary[@"label"] integerValue] sdp:dictionary[@"candidate"]];

    return [[RTCIceCandidate alloc] initWithSdp:dictionary[@"candidate"] sdpMLineIndex:[dictionary[@"label"] intValue] sdpMid:dictionary[@"id"]];
}

@end
