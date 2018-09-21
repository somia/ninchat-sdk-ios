//
//  NINSessionManager+Internal.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

//#import <Client/Client.h>
@import Client;

#import "NINChatSession+Internal.h"

@implementation NINChatSession (Internal)

-(void) sdklog:(NSString*)format, ... {
    if ([self.delegate respondsToSelector:@selector(ninchat:didOutputSDKLog:)]) {
        va_list args;
        va_start(args, format);
        [self.delegate ninchat:self didOutputSDKLog:[[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
    }
}

@end
