//
//  NINWebRTCServerInfo.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

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

@end
