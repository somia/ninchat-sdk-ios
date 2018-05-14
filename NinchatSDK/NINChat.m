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

@end

@implementation NINChat

#pragma mark - Public API

-(nonnull UIViewController*) viewController {
    NSLog(@"Loading initial view controller..");

    // Locate our framework bundle by showing it a class in this framework
    NSBundle* framworkBundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"framworkBundle: %@", framworkBundle);

    // Instantiate our storyboard
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:framworkBundle];
    NSLog(@"storyboard: %@", storyboard);

    // Finally return the initial view controller for that storyboard
    return [storyboard instantiateInitialViewController];
}

-(BOOL) start {
    NSError* error = nil;

    ClientStrings* messageTypes = [ClientStrings new];
    [messageTypes append:@"ninchat.com/*"];

    ClientProps* sessionParams = [ClientProps new];
    if (self.userName != nil) {
        ClientProps* attrs = [ClientProps new];
        [attrs setString:@"name" val:self.userName];
        [sessionParams setObject:@"user_attrs" ref:attrs];
    }
    [sessionParams setStringArray:@"message_types" ref:messageTypes];

    ClientSession* session = [ClientSession new];
    [session setOnSessionEvent:self];
    [session setOnEvent:self];
    [session setOnClose:self];
    [session setOnConnState:self];
    [session setOnLog:self];
    [session setParams:sessionParams error:&error];
    if (error != nil) {
        NSLog(@"Error setting session params: %@", error);
        return NO;
    }
    [session open:&error];
    if (error != nil) {
        NSLog(@"Error opening session: %@", error);
        return NO;
    }

    if (self.queueId != nil) {
        ClientProps* audienceParams = [ClientProps new];
        [audienceParams setString:@"action" val:@"request_audience"];
        [audienceParams setString:@"queue_id" val:self.queueId];
	if (self.audienceMetadataJSON != nil) {
            ClientJSON* json = [[ClientJSON alloc] init:self.audienceMetadataJSON];
            [audienceParams setJSON:@"audience_metadata" ref:json];
        }

        [session send:audienceParams payload:nil error:&error];
        if (error != nil) {
            NSLog(@"Error sending message: %@", error);
            return NO;
        }
    }

    [self.statusDelegate statusDidChange:@"starting"];
    return YES;
}

#pragma mark - From ClientEventHandler

-(void) onEvent:(ClientProps*)params payload:(ClientPayload*)payload lastReply:(BOOL)lastReply {
    NSLog(@"Event: %@", params.string);

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    if (error == nil)
        [self.statusDelegate statusDidChange:event];
}

#pragma mark - From ClientLogHandler

-(void) onLog:(NSString*)msg {
    NSLog(@"Log: %@", msg);
}

#pragma mark - From ClientConnStateHandler

-(void) onConnState:(NSString*)state {
    NSLog(@"Connection state: %@", state);
}

#pragma mark - From ClientCloseHandler

-(void) onClose {
    NSLog(@"Session closed.");
    [self.statusDelegate statusDidChange:@"closed"];
}

#pragma mark - From ClientSessionEventHandler

-(void) onSessionEvent:(ClientProps*)params {
    NSLog(@"Session event: %@", [params string]);

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    if (error == nil)
	[self.statusDelegate statusDidChange:event];
}

#pragma mark - Lifecycle etc.

-(id) init {
    self = [super init];

    if (self != nil) {
    }

    return self;
}

@end
