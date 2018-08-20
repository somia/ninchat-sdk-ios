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
    return @{@"type": @"candidate", @"label": @(self.sdpMLineIndex), @"id": self.sdpMid, @"candidate": self.sdp};
}

@end
