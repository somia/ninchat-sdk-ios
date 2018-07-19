//
//  SessionManager.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

// Import the ported Go SDK framework
@import Client;

#import <stdatomic.h>

#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINQueue.h"
#import "NINChatSession.h"
#import "NINChannelMessage.h"
#import "NINPrivateTypes.h"
#import "NINClientPropsParser.h"

/** Notification name for handling asynchronous completions for actions. */
static NSString* const kActionNotification = @"ninchatsdk.ActionNotification";

/** Notification name for channel_joined event. */
static NSString* const kChannelJoinedNotification = @"ninchatsdk.ChannelJoinedNotification";

/** Notification name for channel being closed or suspended. */
NSString* const kChannelClosedNotification = @"ninchatsdk.ChannelClosedNotification";

@interface NINSessionManager () <ClientSessionEventHandler, ClientEventHandler, ClientCloseHandler, ClientLogHandler, ClientConnStateHandler> {

    /** Sequence for action_id:s in chat actions. */
    atomic_long actionIdSequence;

    /** Mutable queue list. */
    NSMutableArray<NINQueue*>* _queues;

    /** Mutable channel messages list. */
    NSMutableArray<NINChannelMessage*>* _channelMessages;
}

/** Realm ID to use. */
@property (nonatomic, strong) NSString* _Nonnull realmId;

/** Chat session reference. */
@property (nonatomic, strong) ClientSession* session;

/** Current queue id. Nil if not currently in queue. */
@property (nonatomic, strong) NSString* currentQueueId;

/** Currently active channel id - or nil if no active channel. */
@property (nonatomic, strong) NSString* activeChannelId;

@end

// Waits for a matching action notification and calls the specified callback block,
// then unregisters the notification observer.
void connectCallbackToActionCompletion(long actionId, callbackWithErrorBlock completion) {
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
}

@implementation NINSessionManager

#pragma mark - Private methods

/** Returns a new unique action ID. */
-(long) nextActionId {
    return atomic_fetch_add_explicit(&actionIdSequence, 1, memory_order_relaxed);
}

//-(void) waitForAction:(long)actionId completion:(callbackWithErrorBlock)completion {
//    fetchNotification(kActionNotification, ^(NSNotification* note) {
//        NSNumber* eventActionId = note.userInfo[@"action_id"];
//        NSError* error = note.userInfo[@"error"];
//
//        if (eventActionId.longValue == actionId) {
//            if (completion != nil) {
//                completion(error);
//            }
//
//            return YES;
//        }
//
//        return NO;
//    });
//}

/*
 Event: map[realm_queues:map[5npnsgnq009m:map[queue_attrs:map[length:0 name:Test queue]]] event_id:2 action_id:1 event:realm_queues_found realm_id:5npnrkp1009m]
 */
-(void) realmQueuesFound:(ClientProps*)params {
    NSError* error;

    // Clear existing queue list
    [_queues removeAllObjects];

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    ClientProps* queues = [params getObject:@"realm_queues" error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }
    NSLog(@"queues: %@", queues.string);

    NINClientPropsParser* queuesParser = [NINClientPropsParser new];
    [queues accept:queuesParser error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    NSLog(@"Parsed queue map: %@", queuesParser.properties);

    for (NSString* queueId in queuesParser.properties.allKeys) {
        ClientProps* queueProps = [queues getObject:queueId error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        ClientProps* queueAttrs = [queueProps getObject:@"queue_attrs" error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        NSString* queueName = [queueAttrs getString:@"name" error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        [_queues addObject:[NINQueue queueWithId:queueId andName:queueName]];
    }

    NSLog(@"Got queues: %@", _queues);
    
    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

// https://github.com/ninchat/ninchat-api/blob/v2/api.md#audience_enqueued
// https://github.com/ninchat/ninchat-api/blob/v2/api.md#queue_updated
-(void) queueUpdated:(NSString*)eventType params:(ClientProps*)params {
    NSError* error;

    // Clear existing queue list
    [_queues removeAllObjects];

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NSString* queueId = [params getString:@"queue_id" error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    if ([eventType isEqualToString:@"audience_enqueued"]) {
        NSAssert(self.currentQueueId == nil, @"Already have current queue");
        NSLog(@"Queue %@ joined.", queueId);
        self.currentQueueId = queueId;
    }

    long position;
    [params getInt:@"queue_position" val:&position error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    NSLog(@"Queue position: %ld", position);

    if (actionId != 0) {
        postNotification(kActionNotification, @{@"action_id": @(actionId)});
    }
}

-(void) channelUpdated:(ClientProps*)params {
    NSError* error;

    NSAssert(self.activeChannelId != nil, @"No active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel_id: %@", error);
        return;
    }

    if (![channelId isEqualToString:self.activeChannelId]) {
        NSLog(@"Got channel_updated for wrong channel '%@'", channelId);
        return;
    }

    ClientProps* channelAttrs = [params getObject:@"channel_attrs" error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attrs: %@", error);
        return;
    }

    BOOL closed;
    [channelAttrs getBool:@"closed" val:&closed error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attr 'closed': %@", error);
        return;
    }

    BOOL suspended;
    [channelAttrs getBool:@"suspended" val:&suspended error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attr 'suspended': %@", error);
        return;
    }

    if (closed || suspended) {
        postNotification(kChannelClosedNotification, @{});
    }
}

/*
 Inbound text message:

 Event: map[message_time:1.530784885e+09 message_type:ninchat.com/text event_id:7 frames:1 event:message_received message_id:5nsgf1n2004qs message_user_name:Matti Dahlbom channel_id:5npnrkp1009m message_user_id:5i09opdv0049]

 Channel join:

 Event: map[message_time:1.530788844e+09 message_type:ninchat.com/info/join event_id:3 frames:1 channel_id:5npnrkp1009m event:message_received message_id:5nsk7s7c009m2]
 */
-(void) messageReceived:(ClientProps*)params payload:(ClientPayload*)payload {
    NSAssert(self.activeChannelId != nil, @"No active channel");

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

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NSLog(@"Message payload.length = %ld", payload.length);
    for (int i = 0; i < payload.length; i++) {
        NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }

        NINChannelMessage* msg = [NINChannelMessage messageWithTextContent:payloadDict[@"text"] mine:(actionId != 0)];
        [_channelMessages insertObject:msg atIndex:0];
        postNotification(kNewChannelMessageNotification, @{@"message": msg});
        NSLog(@"Got new channel message: %@", msg);
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

/* success:
 Event: map[event_id:2 action_id:1 channel_attrs:map[upload:member disclosed:true disclosed_since:1.530691939e+09 name:General owner_id:02eobjtj public:true] channel_id:5npnrkp1009m channel_members:map[02eobjtj:map[user_attrs:map[iconurl:https://ninchat.s3-eu-west-1.amazonaws.com/u/02eobjtj/4vlngbq500lpo info:map[company:Ninchat url:] name:Antti realname:Antti Laakso admin:true connected:true] member_attrs:map[moderator:true operator:true since:1.530691974e+09]] 5i09opdv0049:map[user_attrs:map[info:map[company:QVIK url:https://qvik.fi] name:Matti Dahlbom realname:Matti Dahlbom connected:true iconurl:https://ninchat.s3-eu-west-1.amazonaws.com/u/5i09opdv0049/5i09qdb50049 idle:1.530706564e+09] member_attrs:map[since:1.530693958e+09]] 5nq6hnnb004qs:map[member_attrs:map[since:1.530707382e+09] user_attrs:map[connected:true guest:true]]] event:channel_joined realm_id:5npnrkp1009m]
 */
-(void) channelJoined:(ClientProps*)params {
    NSError* error = nil;

    NSAssert(self.currentQueueId != nil, @"No current queue");
    NSAssert(self.activeChannelId == nil, @"Already have active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel id: %@", error);
        return;
    }

    NSLog(@"Joined channel '%@'", channelId);

    // Set the currently active channel
    self.activeChannelId = channelId;

    // We are no longer in the queue; clear the queue reference
    self.currentQueueId = nil;

    // Clear current list of messages
    [_channelMessages removeAllObjects];

    // Signal channel join event to the asynchronous listener
    postNotification(kChannelJoinedNotification, @{});
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

#pragma mark - Public methods

-(void) listQueuesWithCompletion:(callbackWithErrorBlock)completion {
    NSAssert(self.session != nil, @"No chat session");

    long actionId = self.nextActionId;

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"describe_realm_queues"];
    [params setInt:@"action_id" val:actionId];
    [params setString:@"realm_id" val:self.realmId];

    NSError* error = nil;
    [self.session send:params payload:nil error:&error];
    if (error != nil) {
        NSLog(@"Error describing queues: %@", error);
        completion(error);
    }
}

// https://github.com/ninchat/ninchat-api/blob/v2/api.md#request_audience
-(void) joinQueueWithId:(NSString*)queueId completion:(callbackWithErrorBlock _Nonnull)completion channelJoined:(emptyBlock _Nonnull)channelJoined {

    NSAssert(self.session != nil, @"No chat session");

    NSLog(@"Joining queue %@..", queueId);

    long actionId = self.nextActionId;

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);

    fetchNotification(kChannelJoinedNotification, ^BOOL(NSNotification* note) {
        channelJoined();
        return YES;
    });

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"request_audience"];
    [params setInt:@"action_id" val:actionId];
    [params setString:@"queue_id" val:queueId];

    NSError* error = nil;
    [self.session send:params payload:nil error:&error];
    if (error != nil) {
        NSLog(@"Error joining queue: %@", error);
        completion(error);
    }
}

// Sends a message to the activa channel. Active channel must exist.
-(void) sendMessageWithActionId:(long)actionId messageType:(NSString*)messageType payloadDict:(NSDictionary*)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion {

    NSAssert(self.session != nil, @"No chat session");

    if (self.activeChannelId == nil) {
        completion(newError(@"No active channel"));
        return;
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"send_message"];
    [params setInt:@"action_id" val:actionId];
    [params setString:@"message_type" val:messageType];
    [params setString:@"channel_id" val:self.activeChannelId];

    NSError* error;
    NSData* payloadContentJsonData = [NSJSONSerialization dataWithJSONObject:payloadDict options:0 error:&error];
    if (error != nil) {
        NSLog(@"Failed to serialize message JSON: %@", error);
        completion(error);
        return;
    }

    ClientPayload* payload = [ClientPayload new];
    [payload append:payloadContentJsonData];

    [self.session send:params payload:payload error:&error];
    if (error != nil) {
        NSLog(@"Error sending message: %@", error);
        completion(error);
    }
}

-(void) sendTextMessage:(NSString*)message completion:(callbackWithErrorBlock _Nonnull)completion {
    NSAssert(self.session != nil, @"No chat session");

    long actionId = self.nextActionId;

    NSDictionary* payloadDict = @{@"text": message};
    [self sendMessageWithActionId:actionId messageType:@"ninchat.com/text" payloadDict:payloadDict completion:completion];

    //TODO remove this
//    NSString* jsonString = [[NSString alloc] initWithData:payloadContentJsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"Payload is: '%@'", jsonString);
//
//    //TODO remove
//    NSMutableString *result = [NSMutableString string];
//    const char *bytes = [payloadContentJsonData bytes];
//    for (int i = 0; i < [payloadContentJsonData length]; i++)
//    {
//        [result appendFormat:@"%02hhx ", (unsigned char)bytes[i]];
//    }
//    NSLog(@"Payload bytes are: %@", result);
}

-(void) closeChat {
    NSLog(@"Shutting down chat Session..");
    self.activeChannelId = nil;
    [self.session close];
    self.session = nil;

    // Signal the delegate that our session has ended
    [self.ninchatSession.delegate ninchatDidEndChatSession:self.ninchatSession];
}

-(void) finishChat:(NSNumber* _Nullable)rating {
    NSAssert(self.session != nil, @"No chat session");

    NSLog(@"finishChat: %@", rating);

    if (rating != nil) {
        long actionId = self.nextActionId;
        NSDictionary* payloadDict = @{@"data": @{@"rating": rating}};

        __weak typeof(self) weakSelf = self;
        [self sendMessageWithActionId:actionId messageType:@"ninchat.com/metadata" payloadDict:payloadDict completion:^(NSError* error) {
            [weakSelf closeChat];
        }];
    } else {
        [self closeChat];
    }
}

-(NSError*) openSession:(startCallbackBlock _Nonnull)callbackBlock {
    NSAssert(self.session == nil, @"Existing chat session found");

    // Make sure our site configuration contains a realm_id
    NSString* realmId = self.siteConfiguration[@"default"][@"audienceRealmId"];
    if ((realmId == nil) || (![realmId isKindOfClass:[NSString class]])) {
        return newError(@"Could not find valid realm id in the site configuration");
    }

    self.realmId = realmId;

    ClientStrings* messageTypes = [ClientStrings new];
    [messageTypes append:@"ninchat.com/*"];

    ClientProps* sessionParams = [ClientProps new];
    if (self.siteSecret != nil) {
        [sessionParams setString:@"site_secret" val:self.siteSecret];
    }

    //TODO where do we get the username?
//    if (self.userName != nil) {
//        ClientProps* attrs = [ClientProps new];
//        [attrs setString:@"name" val:self.userName];
//        [sessionParams setObject:@"user_attrs" ref:attrs];
//    }
    [sessionParams setStringArray:@"message_types" ref:messageTypes];

    //TODO implement a give up -timer?
    // Wait for the session creation event
    fetchNotification(kActionNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSString* eventType = note.userInfo[@"event_type"];
        if ([eventType isEqualToString:@"session_created"]) {
            callbackBlock(note.userInfo[@"error"]);
            return YES;
        }

        return NO;
    });

    __weak typeof(self) weakSelf = self;

    self.session = [ClientSession new];
    [self.session setAddress:kNinchatServerHostName];
    [self.session setOnSessionEvent:weakSelf];
    [self.session setOnEvent:weakSelf];
    [self.session setOnClose:weakSelf];
    [self.session setOnConnState:weakSelf];
    [self.session setOnLog:weakSelf];

    NSError* error = nil;
    [self.session setParams:sessionParams error:&error];
    if (error != nil) {
        NSLog(@"Error setting session params: %@", error);
        return error;
    }
    [self.session open:&error];
    if (error != nil) {
        NSLog(@"Error opening session: %@", error);
        return error;
    }

    /*
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
            return error;
        }
    }
*/
   // [self.statusDelegate statusDidChange:@"starting"];

    return nil;
}

#pragma mark - From ClientEventHandler

-(void) onEvent:(ClientProps*)params payload:(ClientPayload*)payload lastReply:(BOOL)lastReply {
    NSLog(@"Event: %@", params.string);

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    if (error != nil) {
        NSLog(@"Got error getting event data: %@", error);
        return;
    }

    if ([event isEqualToString:@"error"]) {
        [self handleError:params];
    } else if ([event isEqualToString:@"channel_joined"]) {
        [self channelJoined:params];
    } else if ([event isEqualToString:@"message_received"]) {
        [self messageReceived:params payload:payload];
    } else if ([event isEqualToString:@"realm_queues_found"]) {
        [self realmQueuesFound:params];
    } else if ([event isEqualToString:@"audience_enqueued"] || [event isEqualToString:@"queue_updated"]) {
        [self queueUpdated:event params:params];
    } else if ([event isEqualToString:@"channel_updated"]) {
        [self channelUpdated:params];
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
    //[self.statusDelegate statusDidChange:@"closed"];
}

#pragma mark - From ClientSessionEventHandler

-(void) onSessionEvent:(ClientProps*)params {
    NSLog(@"Session event: %@", [params string]);

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    if (error != nil) {
        //TODO what to do here?
        NSLog(@"Error getting session event data: %@", error);
    } else {
        //[self.statusDelegate statusDidChange:event];

        if ([event isEqualToString:@"session_created"]) {
            postNotification(kActionNotification, @{@"event_type": event});
        }
    }
}

#pragma mark - Lifecycle etc.

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

-(id) init {
    self = [super init];

    if (self != nil) {
        actionIdSequence = 1;
        _queues = [NSMutableArray array];
        _channelMessages = [NSMutableArray array];
    }

    return self;
}

@end
