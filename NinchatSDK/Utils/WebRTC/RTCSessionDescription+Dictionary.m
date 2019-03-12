//
//  RTCSessionDescription+JSON.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCSessionDescription+Dictionary.h"

static NSString* const kKeyType = @"type";
static NSString* const kKeySdp = @"sdp";

@implementation RTCSessionDescription (Dictionary)

-(NSDictionary*) dictionary {
    NSString* type = nil;

    switch (self.type) {
        case RTCSdpTypeAnswer:
            type = @"answer";
            break;
        case RTCSdpTypePrAnswer:
            type = @"pranswer";
            break;
        default:
            type = @"offer";
            break;
    }
    
    return @{kKeyType: type, kKeySdp: self.sdp};
}

+(RTCSessionDescription*) fromDictionary:(NSDictionary*)dictionary {
    NSString* type = dictionary[kKeyType];
    NSString* sdp = dictionary[kKeySdp];

    if ((type == nil) || (sdp == nil)) {
        NSLog(@"ERROR: Constructing RTCSessionDescription from incomplete data");
    }

    RTCSdpType typeConstant = RTCSdpTypeOffer;
    if ([type isEqualToString:@"answer"]) {
        typeConstant = RTCSdpTypeAnswer;
    } else if ([type isEqualToString:@"pranswer"]) {
        typeConstant = RTCSdpTypePrAnswer;
    }

    return [[RTCSessionDescription alloc] initWithType:typeConstant sdp:sdp];
}

@end
