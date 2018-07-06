//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import Client;

#import <stdatomic.h>

#import "NINChat.h"
#import "NINMessagesViewController.h"
#import "Utils.h"

static NSString* const kActionNotification = @"ActionNotification";

@interface NINChat () <ClientSessionEventHandler, ClientEventHandler, ClientCloseHandler, ClientLogHandler, ClientConnStateHandler> {
    atomic_long actionIdSequence;
}

/** Chat session reference. */
@property (nonatomic, strong) ClientSession* session;

/** Currently active channel id - or nil if no active channel. */
@property (nonatomic, strong) NSString* activeChannelId;

@end

@implementation NINChat

/** Creates a new NSError with a message. */
NSError* newError(NSString* msg) {
    return [NSError errorWithDomain:@"NinchatSDK" code:1 userInfo:@{@"message": msg}];
}

#pragma mark - Private API

/** Returns a new unique action ID. */
-(long) nextActionId {
    return atomic_fetch_add_explicit(&actionIdSequence, 1, memory_order_relaxed);
}

/*
 Inbound text message:

Event: map[message_time:1.530784885e+09 message_type:ninchat.com/text event_id:7 frames:1 event:message_received message_id:5nsgf1n2004qs message_user_name:Matti Dahlbom channel_id:5npnrkp1009m message_user_id:5i09opdv0049]

 Channel join:

 Event: map[message_time:1.530788844e+09 message_type:ninchat.com/info/join event_id:3 frames:1 channel_id:5npnrkp1009m event:message_received message_id:5nsk7s7c009m2]
 */
-(void) messageReceived:(ClientProps*)params payload:(ClientPayload*)payload {
    NSError* error = nil;
    NSString* messageType = [params getString:@"message_type" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get message_type: %@", error);
        return;
    }

    NSLog(@"Got message_type: %@", messageType);

    if (![messageType isEqualToString:@"ninchat.com/text"]) {
        // Ignore all but text messages
        NSLog(@"Ignoring non-text message.");
        return;
    }

    NSLog(@"Message payload.length = %ld", payload.length);
    NSMutableString* payloadContents = [NSMutableString string];
    for (int i = 0; i < payload.length; i++) {
        NSString* text = [[NSString alloc] initWithData:[payload get:i] encoding:NSUTF8StringEncoding];
        NSLog(@"Payload text %d: %@", i, text);
        NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }

        [payloadContents appendString:payloadDict[@"text"]];
    }

    NSLog(@"Payload contents: %@", payloadContents);

    NSString* actionId = [params getString:@"action_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    postNotification(kActionNotification, @{@"action_id": actionId});
}

/* success:
 Event: map[event_id:2 action_id:1 channel_attrs:map[upload:member disclosed:true disclosed_since:1.530691939e+09 name:General owner_id:02eobjtj public:true] channel_id:5npnrkp1009m channel_members:map[02eobjtj:map[user_attrs:map[iconurl:https://ninchat.s3-eu-west-1.amazonaws.com/u/02eobjtj/4vlngbq500lpo info:map[company:Ninchat url:] name:Antti realname:Antti Laakso admin:true connected:true] member_attrs:map[moderator:true operator:true since:1.530691974e+09]] 5i09opdv0049:map[user_attrs:map[info:map[company:QVIK url:https://qvik.fi] name:Matti Dahlbom realname:Matti Dahlbom connected:true iconurl:https://ninchat.s3-eu-west-1.amazonaws.com/u/5i09opdv0049/5i09qdb50049 idle:1.530706564e+09] member_attrs:map[since:1.530693958e+09]] 5nq6hnnb004qs:map[member_attrs:map[since:1.530707382e+09] user_attrs:map[connected:true guest:true]]] event:channel_joined realm_id:5npnrkp1009m]
*/
-(void) channelJoined:(ClientProps*)params {
    NSError* error = nil;
    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel id: %@", error);
        return;
    }

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NSLog(@"Joined channel '%@'", channelId);

    // Set the currently active channel
    self.activeChannelId = channelId;

    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

/*
 Event: map[event_id:2 action_id:1 channel_id:5npnrkp1009n error_type:channel_not_found event:error]
*/
-(void) handleError:(ClientProps*)params {
    NSError* error = nil;
    NSString* errorType = [params getString:@"error_type" error:&error];
    if (error != nil) {
        NSLog(@"Failed to read error type: %@", error);
        return;
    }

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": newError(errorType)});
}

#pragma mark - Public API

-(nonnull UIViewController*) viewController {
    NSLog(@"Loading initial view controller..");

    // Locate our framework bundle by showing it a class in this framework
    NSBundle* classBundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"frameworkBundle: %@", classBundle);

    UIStoryboard* storyboard = nil;

    // See if this top level bundle contains our storyboard
    if ([classBundle pathForResource:@"Chat" ofType:@"storyboard"] != nil) {
        // This path is taken when using the SDK from a prebuilt .framework.
        NSLog(@"storyboard found in class bundle");
        storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:classBundle];
    } else {
        // This path is taken when using the SDK via Cocoapods module.
        // Locate our UI resource bundle. This is specified in the podspec file.
        NSLog(@"storyboard not found in class bundle");
        NSURL* bundleURL = [classBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
        NSBundle* bundle = [NSBundle bundleWithURL:bundleURL];
        storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];
    }

    NSLog(@"storyboard: %@", storyboard);

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];
    NINMessagesViewController* initialViewController = nil;

    // Find our own initial view controller
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)vc;
        initialViewController = (NINMessagesViewController*)navigationController.topViewController;
    } else if ([vc isKindOfClass:[NINMessagesViewController class]]) {
        initialViewController = (NINMessagesViewController*)vc;
    } else {
        NSLog(@"Invalid initial view controller from Storyboard: %@", vc.class);
        return nil;
    }

    initialViewController.chat = self;
    
    NSLog(@"Instantiated initial view controller: %@", vc);

    return vc;
}

-(void) joinChannelWithId:(NSString*)channelId completion:(void (^)(NSError*))completion {
    NSLog(@"Joining channel '%@'", channelId);

    long actionId = self.nextActionId;

    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];
        NSError* error = note.userInfo[@"error"];

        if (eventActionId.longValue == actionId) {
            if (completion != nil) {
                completion(error);
            }

            return YES;
        }

        return NO;
    });

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"join_channel"];
    [params setInt:@"action_id" val:actionId];
    [params setString:@"channel_id" val:channelId];

    NSError* error = nil;
    [self.session send:params payload:nil error:&error];
    if (error != nil) {
        NSLog(@"Error joining channel: %@", error);
        //TODO error handling
        return;
    }
}

-(void) sendMessage:(NSString*)message completion:(void (^)(NSError*))completion {
    if (self.activeChannelId == nil) {
        if (completion != nil) {
            completion(newError(@"No active channel"));
        }
        return;
    }

    long actionId = self.nextActionId;

    fetchNotification(kActionNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSNumber* msgActionId = note.userInfo[@"action_id"];
        NSError* error = note.userInfo[@"error"];

        if (msgActionId.longValue == actionId) {
            if (completion != nil) {
                completion(error);
            }

            return YES;
        }

        return NO;
    });

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"send_message"];
    [params setInt:@"action_id" val:actionId];
    [params setString:@"message_type" val:@"ninchat.com/text"];
    [params setString:@"channel_id" val:self.activeChannelId];

    NSLog(@"params: %@", params);

    id payloadContentObj = @{@"text": message};
    NSError* error = nil;
    NSData* payloadContentJsonData = [NSJSONSerialization dataWithJSONObject:payloadContentObj options:0 error:&error];
    if (error != nil) {
        NSLog(@"Failed to serialize message JSON: %@", error);
        if (completion != nil) {
            completion(error);
        }
        return;
    }

    NSString* jsonString = [[NSString alloc] initWithData:payloadContentJsonData encoding:NSUTF8StringEncoding];
    NSLog(@"Payload is: '%@'", jsonString);
    // Enclose the JSON in quotes
//    jsonString = [NSString stringWithFormat:@"\"%@\"", jsonString];
//    payloadContentJsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    //TODO remove
    NSMutableString *result = [NSMutableString string];
    const char *bytes = [payloadContentJsonData bytes];
    for (int i = 0; i < [payloadContentJsonData length]; i++)
    {
        [result appendFormat:@"%02hhx ", (unsigned char)bytes[i]];
    }
    NSLog(@"Payload bytes are: %@", result);

    ClientPayload* payload = [ClientPayload new];
    [payload append:payloadContentJsonData];

    NSLog(@"Sending message '%@' to channel '%@'", message, self.activeChannelId);

    BOOL sendResult = [self.session send:params payload:payload error:&error];
    if (error != nil) {
        NSLog(@"Error sending message: %@", error);
        if (completion != nil) {
            completion(error);
        }
        return;
    }

    NSLog(@"session.send() result: %@", sendResult ? @"YES" : @"NO");
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

    self.session = [ClientSession new];
    [self.session setOnSessionEvent:self];
    [self.session setOnEvent:self];
    [self.session setOnClose:self];
    [self.session setOnConnState:self];
    [self.session setOnLog:self];
    [self.session setParams:sessionParams error:&error];
    if (error != nil) {
        NSLog(@"Error setting session params: %@", error);
        return NO;
    }
    [self.session open:&error];
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

        [self.session send:audienceParams payload:nil error:&error];
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
    if (error != nil) {
        NSLog(@"Got error getting event data: %@", error);
    } else {
        if ([event isEqualToString:@"error"]) {
            [self handleError:params];
        } else if ([event isEqualToString:@"channel_joined"]) {
            [self channelJoined:params];
        } else if ([event isEqualToString:@"message_received"]) {
            [self messageReceived:params payload:payload];
        }

        [self.statusDelegate statusDidChange:event];
    }
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
    if (error != nil) {
        NSLog(@"Error getting session event data: %@", error);
    } else {
        [self.statusDelegate statusDidChange:event];
    }
}

#pragma mark - Lifecycle etc.

-(id) init {
    self = [super init];

    if (self != nil) {
        actionIdSequence = 1;
    }

    return self;
}

@end
