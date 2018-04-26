//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import Client;

#import "NINChat.h"

@interface NINChat () <ClientSessionEventHandler, ClientEventHandler, ClientCloseHandler, ClientLogHandler, ClientConnStateHandler>

@property ClientCaller* caller;

@end

@implementation NINChat

#pragma mark - Public API

+(instancetype) create {
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    //    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs

    NINChat* client = [NINChat new];

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

-(BOOL) connectionTest {
    NSError* error = nil;

    ClientStrings* messageTypes = [ClientStrings new];
    [messageTypes append:@"ninchat.com/*"];

    ClientProps* sessionParams = [ClientProps new];
    [sessionParams setStringArray:@"message_types" ref:messageTypes];

    ClientSession* session = [ClientSession new];
    [session setOnSessionEvent:self];
    [session setOnEvent:self];
    [session setOnClose:self];
    [session setOnConnState:self];
    [session setOnLog:self];
    [session setParams:sessionParams error:&error];
    if (error != nil) {
        DDLogError(@"Error setting session params: %@", error);
        return NO;
    }
    [session open:&error];
    if (error != nil) {
        DDLogError(@"Error opening session: %@", error);
        return NO;
    }

    ClientProps* sendParams = [ClientProps new];
    [sendParams setString:@"action" val:@"send_message"];
    [sendParams setString:@"user_id" val:@"007"];
    [sendParams setString:@"message_type" val:@"ninchat.com/no-such-message-type"];

    ClientPayload* sendPayload = [ClientPayload new];
    NSString* msgJson = @"{\"text\": \"asdf\"}";
    NSData* msgData = [msgJson dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    [sendPayload append:msgData];

    [session send:sendParams payload:sendPayload error:&error];
    if (error != nil) {
        DDLogError(@"Error sending message: %@", error);
        return NO;
    }

    return YES;
}

#pragma mark - From ClientEventHandler

-(void) onEvent:(ClientProps*)params payload:(ClientPayload*)payload lastReply:(BOOL)lastReply {
    DDLogDebug(@"Event: %@", params.string);
}

#pragma mark - From ClientLogHandler

-(void) onLog:(NSString*)msg {
    DDLogDebug(@"Log: %@", msg);
}

#pragma mark - From ClientConnStateHandler

-(void) onConnState:(NSString*)state {
    DDLogDebug(@"Connection state: %@", state);
}

#pragma mark - From ClientCloseHandler

-(void) onClose {
    DDLogDebug(@"Session closed.");
}

#pragma mark - From ClientSessionEventHandler

-(void) onSessionEvent:(ClientProps*)params {
    DDLogDebug(@"Session event: %@", [params string]);
}

#pragma mark - Lifecycle etc.

-(id) init {
    self = [super init];

    if (self != nil) {
        self.caller = [ClientCaller new];
        DDLogDebug(@"Created Go language ClientCaller: %@", self.caller);
    }

    return self;
}

@end
