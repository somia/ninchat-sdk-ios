//
//  NINWebRTCServerInfo.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <libjingle_peerconnection/RTCICEServer.h>

#import "NINWebRTCServerInfo.h"

@interface NINWebRTCServerInfo ()

@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* credential;

@end

@implementation NINWebRTCServerInfo

+(NINWebRTCServerInfo*) serverWithURL:(NSString*)url username:(NSString*)username credential:(NSString*)credential {
    NINWebRTCServerInfo* info = [NINWebRTCServerInfo new];
    info.url = url;
    info.username = username;
    info.credential = credential;

    return info;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"WebRTC server url: %@", self.url];
}

-(RTCICEServer*) iceServer {
    NSString* username = (self.username != nil) ? self.username : @"";
    NSString* password = (self.credential != nil) ? self.credential : @"";

    return [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:self.url] username:username password:password];
}

@end