//
//  SessionManager.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

// Import the ported Go SDK framework
@import Client;

#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINQueue.h"
#import "NINChatSession.h"
#import "NINChannelMessage.h"
#import "NINChannelUser.h"
#import "NINPrivateTypes.h"
#import "NINClientPropsParser.h"
#import "NINWebRTCServerInfo.h"
#import "NINWebRTCClient.h"

/** Notification name for handling asynchronous completions for actions. */
static NSString* const kActionNotification = @"ninchatsdk.ActionNotification";

/** Notification name for channel_joined event. */
static NSString* const kChannelJoinedNotification = @"ninchatsdk.ChannelJoinedNotification";

NSString* _Nonnull const kNINWebRTCSignalNotification = @"ninchatsdk.NWebRTCSignalNotification";
NSString* const kNINChannelClosedNotification = @"ninchatsdk.ChannelClosedNotification";

// WebRTC related message types
NSString* _Nonnull const kNINMessageTypeWebRTCIceCandidate = @"ninchat.com/rtc/ice-candidate";
NSString* _Nonnull const kNINMessageTypeWebRTCAnswer = @"ninchat.com/rtc/answer";
NSString* _Nonnull const kNINMessageTypeWebRTCOffer = @"ninchat.com/rtc/offer";
NSString* _Nonnull const kNINMessageTypeWebRTCCall = @"ninchat.com/rtc/call";
NSString* _Nonnull const kNINMessageTypeWebRTCPickup = @"ninchat.com/rtc/pick-up";
NSString* _Nonnull const kNINMessageTypeWebRTCHangup = @"ninchat.com/rtc/hang-up";

/**
 This implementation is written against the following API specification:

 https://github.com/ninchat/ninchat-api/blob/v2/api.md
 */
@interface NINSessionManager () <ClientSessionEventHandler, ClientEventHandler, ClientCloseHandler, ClientLogHandler, ClientConnStateHandler> {

    /** Mutable queue list. */
    NSMutableArray<NINQueue*>* _queues;

    /** Mutable channel messages list. */
    NSMutableArray<NINChannelMessage*>* _channelMessages;

    /** Channel user map; ID -> NINChannelUser. */
    NSMutableDictionary<NSString*, NINChannelUser*>* _channelUsers;
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
        NSCAssert(self.currentQueueId == nil, @"Already have current queue");
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

-(NINChannelUser*) parseUserAttrs:(ClientProps*)userAttrs userID:(NSString*)userID {
    NSError* error;

    NSString* iconURL = [userAttrs getString:@"iconurl" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get iconurl: %@", error);
        return nil;
    }

    NSString* displayName = [userAttrs getString:@"name" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get name: %@", error);
        return nil;
    }

    NSString* realName = [userAttrs getString:@"realname" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get realname: %@", error);
        return nil;
    }

    BOOL guest = NO;
    [userAttrs getBool:@"guest" val:&guest error:&error];
    if (error != nil) {
        NSLog(@"Failed to get guest: %@", error);
        return nil;
    }

    return [NINChannelUser userWithID:userID realName:realName displayName:displayName iconURL:iconURL guest:guest];
}

/*Event: map[event_id:6 event:user_updated user_attrs:map[realname:Matti Dahlbom connected:true iconurl:https://ninchat-file-test-eu-central-1.s3-eu-central-1.amazonaws.com/u/5npsj2ag00m3g/5ogokj8m00m3g info:map[company:QVIK url:] name:Matti Dahlbom] user_id:5npsj2ag00m3g]*/
-(void) userUpdated:(ClientProps*)params {
    NSError* error;

    NSCAssert(self.activeChannelId != nil, @"No active channel");

    NSString* userID = [params getString:@"user_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_id: %@", error);
        return;
    }

    ClientProps* userAttrs = [params getObject:@"user_attrs" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_attrs: %@", error);
        return;
    }

    _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
}

-(void) channelUpdated:(ClientProps*)params {
    NSError* error;

    NSCAssert(self.activeChannelId != nil, @"No active channel");

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
        postNotification(kNINChannelClosedNotification, @{});
    }
}

// Processes the response to the WebRTC connectivity ICE query
-(void) iceBegun:(ClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    // Parse the STUN server list
    ClientObjects* stunServers = [params getObjectArray:@"stun_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get stun_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* stunServerArray = [NSMutableArray array];
    for (int i = 0; i < stunServers.length; i++) {
        ClientProps* serverProps = [stunServers get:i];
        ClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
        if (error != nil) {
            NSLog(@"Could not get stun_servers.urls: %@", error);
            return;
        }
        for (int j = 0; j < urls.length; j++) {
            [stunServerArray addObject:[NINWebRTCServerInfo serverWithURL:[urls get:j] username:nil credential:nil]];
        }
    }
    NSLog(@"Parsed STUN servers: %@", stunServerArray);

    // Parse the TURN server list
    ClientObjects* turnServers = [params getObjectArray:@"turn_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get turn_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* turnServerArray = [NSMutableArray array];
    for (int i = 0; i < turnServers.length; i++) {
        ClientProps* serverProps = [turnServers get:i];

        NSString* username = [serverProps getString:@"username" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.username: %@", error);
            return;
        }

        NSString* credential = [serverProps getString:@"credential" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.credential: %@", error);
            return;
        }

        ClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.urls: %@", error);
            return;
        }
        for (int j = 0; j < urls.length; j++) {
            [turnServerArray addObject:[NINWebRTCServerInfo serverWithURL:[urls get:j] username:username credential:credential]];
        }
    }
    NSLog(@"Parsed TURN servers: %@", turnServerArray);

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"stunServers": stunServerArray, @"turnServers": turnServerArray});
}

-(void) handleInboundMessage:(ClientProps*)params payload:(ClientPayload*)payload actionId:(long)actionId {
    NSError* error = nil;
    NSString* messageType = [params getString:@"message_type" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get message_type: %@", error);
        return;
    }

    NSLog(@"Got message_type: %@, actionId: %ld", messageType, actionId);

    if ([messageType isEqualToString:kNINMessageTypeWebRTCIceCandidate] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCAnswer] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCOffer] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCCall] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCHangup]) {

        if (actionId != 0) {
            // This message originates from me; we can ignore it.
            return;
        }

        for (int i = 0; i < payload.length; i++) {
            // Handle a WebRTC signaling message
            NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
            if (error != nil) {
                NSLog(@"Failed to deserialize message JSON: %@", error);
                return;
            }

            postNotification(kNINWebRTCSignalNotification, @{@"messageType": messageType, @"payload": payloadDict});
        }
        return;
    }

    if (![messageType isEqualToString:@"ninchat.com/text"]) {
        // Ignore all but text messages
        NSLog(@"Ignoring non-text message.");
        return;
    }

    NSString* messageUserID = [params getString:@"message_user_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get message_user_id: %@", error);
        return;
    }

    NINChannelUser* messageUser = _channelUsers[messageUserID];
    if (messageUser == nil) {
        NSLog(@"Message from unknown user: %@", messageUserID);
    }

    NSLog(@"Message payload.length = %ld", payload.length);
    for (int i = 0; i < payload.length; i++) {
        NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }


        NINChannelMessage* msg = [NINChannelMessage messageWithTextContent:payloadDict[@"text"] senderName:messageUser.displayName avatarURL:messageUser.iconURL mine:(actionId != 0)];
        [_channelMessages insertObject:msg atIndex:0];
        postNotification(kNewChannelMessageNotification, @{@"message": msg});
        NSLog(@"Got new channel message: %@", msg);
    }
}

-(void) messageReceived:(ClientProps*)params payload:(ClientPayload*)payload {
    NSCAssert(self.activeChannelId != nil, @"No active channel");

    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    [self handleInboundMessage:params payload:payload actionId:actionId];

    if (actionId != 0) {
        postNotification(kActionNotification, @{@"action_id": @(actionId)});
    }
}

/*Event: map[channel_id:5scjf4tm006u8 channel_members:map[5npsj2ag00m3g:map[user_attrs:map[connected:true iconurl:https://ninchat-file-test-eu-central-1.s3-eu-central-1.amazonaws.com/u/5npsj2ag00m3g/5ogokj8m00m3g info:map[company:QVIK url:] name:Matti Dahlbom realname:Matti Dahlbom] member_attrs:map[since:1.535619872e+09 operator:true]] 5scjf0m5006u8:map[user_attrs:map[connected:true guest:true] member_attrs:map[since:1.535619872e+09]]] event:channel_joined realm_id:5lmphjc200m3g event_id:4 channel_attrs:map[anonymous:true audience_id:5scjf26q006u8 private:true requester_id:5scjf0m5006u8 upload:member disclosed:true disclosed_since:1.535619872e+09 owner_id:0498gd6d queue_id:5lmpjrbl00m3g]]
 */
-(void) channelJoined:(ClientProps*)params {
    NSError* error = nil;

    NSCAssert(self.currentQueueId != nil, @"No current queue");
    NSCAssert(self.activeChannelId == nil, @"Already have active channel");

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

    // Clear current list of messages and users
    [_channelMessages removeAllObjects];
    [_channelUsers removeAllObjects];

    // Extract the channel members' data
    ClientProps* members = [params getObject:@"channel_members" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel_members: %@", error);
        return;
    }

    NINClientPropsParser* memberParser = [NINClientPropsParser new];
    [members accept:memberParser error:&error];
    if (error != nil) {
        NSLog(@"Failed to traverse members array: %@", error);
        return;
    }

    for (NSString* userID in memberParser.properties.allKeys) {
        ClientProps* memberAttrs = memberParser.properties[userID];
        ClientProps* userAttrs = [memberAttrs getObject:@"user_attrs" error:&error];
        if (error != nil) {
            NSLog(@"Failed to get user_attrs: %@", error);
            continue;
        }

        _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
    }

    //TODO remove; this is test data
    [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"first short msg" senderName:@"Kalle Katajainen" avatarURL:@"https://bit.ly/2NvjgTy" mine:NO]];
    [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"My reply" senderName:@"Matti Dahlbom" avatarURL:@"https://bit.ly/2ww2E6V" mine:YES]];
    [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"So then heres a longer message which is supposed to require several lines of text to render the whole text into the bubble.." senderName:@"Kalle Katajainen" avatarURL:@"https://bit.ly/2NvjgTy" mine:NO]];
    [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply" senderName:@"Matti Dahlbom" avatarURL:@"https://bit.ly/2ww2E6V" mine:YES]];

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
    NSCAssert(self.session != nil, @"No chat session");

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"describe_realm_queues"];
    [params setString:@"realm_id" val:self.realmId];

    NSError* error = nil;
    int64_t actionId;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error describing queues: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

// https://github.com/ninchat/ninchat-api/blob/v2/api.md#request_audience
-(void) joinQueueWithId:(NSString*)queueId completion:(callbackWithErrorBlock _Nonnull)completion channelJoined:(emptyBlock _Nonnull)channelJoined {

    NSCAssert(self.session != nil, @"No chat session");

    NSLog(@"Joining queue %@..", queueId);

    fetchNotification(kChannelJoinedNotification, ^BOOL(NSNotification* note) {
        channelJoined();
        return YES;
    });

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"request_audience"];
    [params setString:@"queue_id" val:queueId];

    int64_t actionId;
    NSError* error = nil;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error joining queue: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

// Retrieves the WebRTC ICE STUN/TURN server details
-(void) beginICEWithCompletionCallback:(beginICECallbackBlock _Nonnull)completion {
    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"begin_ice"];

    int64_t actionId;
    NSError* error = nil;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error calling begin_ice: %@", error);
        completion(error, nil, nil);
    }

    // When this action completes, trigger the completion block callback
    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];

        if (eventActionId.longValue == actionId) {
            NSError* error = note.userInfo[@"error"];
            NSArray* stunServers = note.userInfo[@"stunServers"];
            NSArray* turnServers = note.userInfo[@"turnServers"];

            completion(error, stunServers, turnServers);
            return YES;
        }

        return NO;
    });
}

// Sends a message to the activa channel. Active channel must exist.
-(long) sendMessageWithMessageType:(NSString*)messageType payloadDict:(NSDictionary*)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion {

    NSCAssert(self.session != nil, @"No chat session");

    if (self.activeChannelId == nil) {
        completion(newError(@"No active channel"));
        return -1;
    }

    ClientProps* params = [ClientProps new];
    [params setString:@"action" val:@"send_message"];
    [params setString:@"message_type" val:messageType];
    [params setString:@"channel_id" val:self.activeChannelId];
    //TODO add support for message_recipient_ids ?

    if ([messageType hasPrefix:@"ninchat.com/rtc/"]) {
        // Add message_ttl to all rtc signaling messages
        [params setInt:@"message_ttl" val:10];
    }

    NSLog(@"Sending message with type '%@' and payload: %@", messageType, payloadDict);
    
    NSError* error;
    NSData* payloadContentJsonData = [NSJSONSerialization dataWithJSONObject:payloadDict options:0 error:&error];
    if (error != nil) {
        NSLog(@"Failed to serialize message JSON: %@", error);
        completion(error);
        return -1;
    }

    ClientPayload* payload = [ClientPayload new];
    [payload append:payloadContentJsonData];

    int64_t actionId = -1;
    [self.session send:params payload:payload actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error sending message: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);

    return actionId;
}

// Sends a text message to the current channel
-(void) sendTextMessage:(NSString*)message completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.session != nil, @"No chat session");

    NSDictionary* payloadDict = @{@"text": message};
    [self sendMessageWithMessageType:@"ninchat.com/text" payloadDict:payloadDict completion:completion];
}

// Low-level shutdown of the chatsession; invalidates session resource.
-(void) closeChat {
    NSLog(@"Shutting down chat Session..");
    self.activeChannelId = nil;
    [self.session close];
    self.session = nil;

    // Signal the delegate that our session has ended
    [self.ninchatSession.delegate ninchatDidEndChatSession:self.ninchatSession];
}

// High-level chat ending; sends channel metadata and then closes session.
-(void) finishChat:(NSNumber* _Nullable)rating {
    NSCAssert(self.session != nil, @"No chat session");

    NSLog(@"finishChat: %@", rating);

    if (rating != nil) {
        NSDictionary* payloadDict = @{@"data": @{@"rating": rating}};

        __weak typeof(self) weakSelf = self;
        [self sendMessageWithMessageType:@"ninchat.com/metadata" payloadDict:payloadDict completion:^(NSError* error) {
            [weakSelf closeChat];
        }];
    } else {
        [self closeChat];
    }
}

-(NSError*) openSession:(startCallbackBlock _Nonnull)callbackBlock {
    NSCAssert(self.session == nil, @"Existing chat session found");

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
    } else if ([event isEqualToString:@"ice_begun"]) {
        [self iceBegun:params];
    } else if ([event isEqualToString:@"user_updated"]) {
        [self userUpdated:params];
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
        _queues = [NSMutableArray array];
        _channelMessages = [NSMutableArray array];
        _channelUsers = [NSMutableDictionary dictionary];
    }

    return self;
}

@end
