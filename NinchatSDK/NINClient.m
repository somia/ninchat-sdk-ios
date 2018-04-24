//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Ninchat. All rights reserved.
//

@import Client;

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

-(nonnull UIViewController*) initialViewController {
    // Locate our framework bundle by showing it a class in this framework
    NSBundle* framworkBundle = [NSBundle bundleForClass:[self class]];

    // Locate our resource bundle
    NSURL* bundleURL = [framworkBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithURL:bundleURL];

    // Then, instantiate our Chat storyboard from that bundle
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // Finally return the initial view controller for that storyboard
    return [storyboard instantiateInitialViewController];
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
