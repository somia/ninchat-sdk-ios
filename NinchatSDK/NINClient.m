//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Ninchat. All rights reserved.
//

#import <Client/Client.h>

#import "NINClient.h"

@interface NINClient ()

@property ClientCaller* caller;

@end

@implementation NINClient

+(instancetype) create {
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    //    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs

    NINClient* client = [NINClient new];

    //TODO init stuff on client

    return client;
}

-(id) init {
    self = [super init];

    if (self != nil) {
        self.caller = [ClientCaller new];
        DDLogDebug(@"Created Go language ClientCaller: %@", self.caller);
    }

    return self;
}

@end
