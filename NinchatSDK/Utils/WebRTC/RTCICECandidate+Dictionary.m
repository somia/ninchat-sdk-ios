//
//  RTCICECandidate+Dictionary.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCICECandidate+Dictionary.h"

@implementation RTCICECandidate (Dictionary)

-(NSDictionary*) dictionary {
    return @{@"label": @(self.sdpMLineIndex), @"id": self.sdpMid, @"candidate": self.sdp};
}

+(RTCICECandidate*) fromDictionary:(NSDictionary*)dictionary {
    return [[RTCICECandidate alloc] initWithMid:dictionary[@"id"] index:[dictionary[@"label"] integerValue] sdp:dictionary[@"candidate"]];
}

@end
