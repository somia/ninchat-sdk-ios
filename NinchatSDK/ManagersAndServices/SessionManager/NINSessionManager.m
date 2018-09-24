//
//  SessionManager.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINQueue.h"
#import "NINChatSession.h"
#import "NINChatMessage.h"
#import "NINChannelMessage.h"
#import "NINChatMetaMessage.h"
#import "NINChannelUser.h"
#import "NINPrivateTypes.h"
#import "NINClientPropsParser.h"
#import "NINWebRTCServerInfo.h"
#import "NINWebRTCClient.h"
#import "NINChatSession+Internal.h"
#import "NINFileInfo.h"
#import "NINToast.h"

typedef void (^getFileInfoCallback)(NSError* _Nullable error, NINFileInfo* fileInfo);

// UI texts
static NSString* const kConversationStartedText = @"Audience in queue {{queue}} accepted.";
static NSString* const kConversationEndedText = @"Conversation ended";
static NSString* const kCloseChatButtonText = @"Close chat";

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
 * This class is used to work around circular reference memory leaks caused by the gomobile bind.
 * It cannot hold a reference to 'proxy objects' ie. the ClientSession.
 */
@interface SessionCallbackHandler : NSObject <NINLowLevelClientSessionEventHandler, NINLowLevelClientEventHandler, NINLowLevelClientCloseHandler, NINLowLevelClientLogHandler, NINLowLevelClientConnStateHandler>
@property (nonatomic, weak) NINSessionManager* sessionManager;
@end

/**
 This implementation is written against the following API specification:

 https://github.com/ninchat/ninchat-api/blob/v2/api.md
 */
@interface NINSessionManager () {
    /** Mutable queue list. */
    NSMutableArray<NINQueue*>* _queues;

    /** Mutable channel messages list. */
    NSMutableArray<id<NINChatMessage>>* _chatMessages;

    /** Channel user map; ID -> NINChannelUser. */
    NSMutableDictionary<NSString*, NINChannelUser*>* _channelUsers;
}

/** Realm ID to use. */
@property (nonatomic, strong) NSString* _Nonnull realmId;

/** Low-level chat session reference. */
@property (nonatomic, strong) NINLowLevelClientSession* session;

/** Current queue id. Nil if not currently in queue. */
@property (nonatomic, strong) NSString* currentQueueID;

/** Currently active channel id - or nil if no active channel. */
@property (nonatomic, strong) NSString* currentChannelID;

/** Channel join observer; while in queue. */
@property (nonatomic, strong) id<NSObject> channelJoinObserver;

/** Queue progress observer. */
@property (nonatomic, strong) id<NSObject> queueProgressObserver;

@end

// Waits for a matching action notification and calls the specified callback block,
// then unregisters the notification observer.
void connectCallbackToActionCompletion(int64_t actionId, callbackWithErrorBlock completion) {
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

-(void) realmQueuesFound:(NINLowLevelClientProps*)params {
    NSError* error;

    // Clear existing queue list
    [self.ninchatSession sdklog:@"Realm queues found - flushing list of previously available queues."];
    [_queues removeAllObjects];

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NINLowLevelClientProps* queues = [params getObject:@"realm_queues" error:&error];
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
        NINLowLevelClientProps* queueProps = [queues getObject:queueId error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        NINLowLevelClientProps* queueAttrs = [queueProps getObject:@"queue_attrs" error:&error];
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
-(void) queueUpdated:(NSString*)eventType params:(NINLowLevelClientProps*)params {
    NSError* error;

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
        NSCAssert(self.currentQueueID == nil, @"Already have current queue");
        NSLog(@"Queue %@ joined.", queueId);
        self.currentQueueID = queueId;
    }

    long position;
    [params getInt:@"queue_position" val:&position error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    NSLog(@"Queue position: %ld", position);

    if ((actionId != 0) || [eventType isEqualToString:@"queue_updated"]) {
        postNotification(kActionNotification, @{@"event": eventType, @"action_id": @(actionId), @"queue_position": @(position), @"queue_id": queueId});
    }
}

-(NINChannelUser*) parseUserAttrs:(NINLowLevelClientProps*)userAttrs userID:(NSString*)userID {
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

-(void) userUpdated:(NINLowLevelClientProps*)params {
    NSError* error;

    NSCAssert(self.currentChannelID != nil, @"No active channel");

    NSString* userID = [params getString:@"user_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_id: %@", error);
        return;
    }

    NINLowLevelClientProps* userAttrs = [params getObject:@"user_attrs" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_attrs: %@", error);
        return;
    }

    _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
}

-(void) fileFound:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* fileID = [params getString:@"file_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* url = [params getString:@"file_url" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    double expiry;
    [params getFloat:@"url_expiry" val:&expiry error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");
    NSDate* urlExpiry = [NSDate dateWithTimeIntervalSince1970:expiry];

    NINLowLevelClientProps* fileAttributes = [params getObject:@"file_attrs" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* mimeType = [fileAttributes getString:@"type" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* name = [fileAttributes getString:@"name" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    long size;
    [fileAttributes getInt:@"size" val:&size error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NINLowLevelClientProps* thumbnail = [fileAttributes getObject:@"thumbnail" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    CGFloat aspectRatio = 1.0;

    // If thumbnail object is present, use its dimensions to calculate image aspect ratio
    if (thumbnail != nil) {
        long width;
        [thumbnail getInt:@"width" val:&width error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        long height;
        [thumbnail getInt:@"height" val:&height error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        aspectRatio = (CGFloat)width / (CGFloat)height;
    }

    //TODO handle other file types too?
    NINFileInfo* fileInfo = [NINFileInfo imageFileInfoWithID:fileID name:name mimeType:mimeType size:size url:url urlExpiry:urlExpiry aspectRatio:aspectRatio];

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"fileInfo": fileInfo});
}

-(void) channelJoined:(NINLowLevelClientProps*)params {
    NSError* error = nil;

    NSCAssert(self.currentQueueID != nil, @"No current queue");
    NSCAssert(self.currentChannelID == nil, @"Already have active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel id: %@", error);
        return;
    }

    NSLog(@"Joined channel '%@'", channelId);

    // Set the currently active channel
    self.currentChannelID = channelId;

    // We are no longer in the queue; clear the queue reference
    self.currentQueueID = nil;

    // Clear current list of messages and users
    [_chatMessages removeAllObjects];
    [_channelUsers removeAllObjects];

    // Insert a meta message about the conversation start
    [self addNewChatMessage:[NINChatMetaMessage messageWithText:[self translation:kConversationStartedText formatParams:nil] timestamp:[NSDate date] closeChatButtonTitle:nil]];

    // Extract the channel members' data
    NINLowLevelClientProps* members = [params getObject:@"channel_members" error:&error];
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
        NINLowLevelClientProps* memberAttrs = memberParser.properties[userID];
        NINLowLevelClientProps* userAttrs = [memberAttrs getObject:@"user_attrs" error:&error];
        if (error != nil) {
            NSLog(@"Failed to get user_attrs: %@", error);
            continue;
        }

        _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
    }

    //TODO remove; this is test data

//     NINChannelMessage* msg1 = [NINChannelMessage messageWithID:@"1" textContent:nil senderName:@"Kalle" avatarURL:nil timestamp:[NSDate date] mine:YES series:NO senderUserID:@"1"];
    NINChannelUser* user1 = [NINChannelUser userWithID:@"1" realName:@"Matti Dahlbom" displayName:@"Matti Dahlbom" iconURL:@"http://777-team.org/~matti/pics/larvi.jpg" guest:NO];
    NINFileInfo* attachment = [NINFileInfo imageFileInfoWithID:@"1" name:@"123.jpg" mimeType:@"image/jpeg" size:123 url:@"http://777-team.org/~matti/pics/larvi.jpg" urlExpiry:nil aspectRatio:0.7];
    NINChannelMessage* msg1 = [NINChannelMessage messageWithID:@"1" textContent:nil sender:user1 timestamp:[NSDate date] mine:NO attachment:attachment];
    [self addNewChatMessage:msg1];

    /*
     [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"first short msg" senderName:@"Kalle Katajainen" avatarURL:@"https://bit.ly/2NvjgTy" timestamp:[NSDate date] mine:NO series:NO senderUserID:@"1"]];
     [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"My reply" senderName:@"Matti Dahlbom" avatarURL:@"https://bit.ly/2ww2E6V" timestamp:[NSDate date] mine:YES series:NO senderUserID:@"2"]];
     [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"So then heres a longer message which is supposed to require several lines of text to render the whole text into the bubble.." senderName:@"Kalle Katajainen" avatarURL:@"https://bit.ly/2NvjgTy" timestamp:[NSDate date] mine:NO series:NO senderUserID:@"1"]];
     [_channelMessages addObject:[NINChannelMessage messageWithTextContent:@"My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply My long reply" senderName:@"Matti Dahlbom" avatarURL:@"https://bit.ly/2ww2E6V" timestamp:[NSDate date] mine:YES series:NO senderUserID:@"2"]];
     */
    // Signal channel join event to the asynchronous listener
    postNotification(kChannelJoinedNotification, @{});
}

-(void) channelParted:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* channelID = [params getString:@"channel_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"channel_id": channelID});
}

-(void) channelUpdated:(NINLowLevelClientProps*)params {
    NSError* error;

    NSCAssert(self.currentChannelID != nil, @"No active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel_id: %@", error);
        return;
    }

    if (![channelId isEqualToString:self.currentChannelID]) {
        NSLog(@"Got channel_updated for wrong channel '%@'", channelId);
        return;
    }

    NINLowLevelClientProps* channelAttrs = [params getObject:@"channel_attrs" error:&error];
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
        NSString* text = [self translation:kConversationEndedText formatParams:nil];
        NSString* closeButtonTitle = [self translation:kCloseChatButtonText formatParams:nil];
        [self addNewChatMessage:[NINChatMetaMessage messageWithText:text timestamp:[NSDate date] closeChatButtonTitle:closeButtonTitle]];

        postNotification(kNINChannelClosedNotification, @{});
    }
}

// Processes the response to the WebRTC connectivity ICE query
-(void) iceBegun:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    // Parse the STUN server list
    NINLowLevelClientObjects* stunServers = [params getObjectArray:@"stun_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get stun_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* stunServerArray = [NSMutableArray array];
    for (int i = 0; i < stunServers.length; i++) {
        NINLowLevelClientProps* serverProps = [stunServers get:i];
        NINLowLevelClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
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
    NINLowLevelClientObjects* turnServers = [params getObjectArray:@"turn_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get turn_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* turnServerArray = [NSMutableArray array];
    for (int i = 0; i < turnServers.length; i++) {
        NINLowLevelClientProps* serverProps = [turnServers get:i];

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

        NINLowLevelClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
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

// Asynchronously retrieves file info
-(void) describeFile:(NSString*)fileID completion:(getFileInfoCallback)completion {
    // Fetch the file info, including the (temporary) download url for the file
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"describe_file"];
    [params setString:@"file_id" val:fileID];

    NSError* error = nil;
    int64_t actionId;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error getting file info: %@", error);
        completion(error, nil);
        return;
    }

    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];
        NSError* error = note.userInfo[@"error"];

        if (eventActionId.longValue == actionId) {
            completion(error, (NINFileInfo*)note.userInfo[@"fileInfo"]);
            return YES;
        }

        return NO;
    });
}

-(void) addNewChatMessage:(id<NINChatMessage>)message {
    NSCAssert([NSThread isMainThread], @"Must only be called on the main thread.");

    if ([message isKindOfClass:NINChannelMessage.class]) {
        // Check if the previous message was sent by the same user, ie. is the
        // message part of a series
        NINChannelMessage* channelMessage = (NINChannelMessage*)message;
        channelMessage.series = NO;
        NINChannelMessage* prevMsg = (NINChannelMessage*)_chatMessages.firstObject;
        if ((prevMsg != nil) && [prevMsg isKindOfClass:NINChannelMessage.class]) {
            channelMessage.series = [prevMsg.sender.userID isEqualToString:channelMessage.sender.userID];
        }
    }

    [_chatMessages insertObject:message atIndex:0];

    postNotification(kNewChannelMessageNotification, @{@"message": message});
    NSLog(@"Added new channel message: %@", message);
}

-(void) handleInboundChatMessageWithPayload:(NINLowLevelClientPayload*)payload messageID:(NSString*)messageID messageUser:(NINChannelUser*)messageUser messageTime:(CGFloat)messageTime actionId:(long)actionId{

    NSError* error = nil;

    for (int i = 0; i < payload.length; i++) {
        NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }

        BOOL hasAttachment = NO;
        NSArray* fileObjectsList = payloadDict[@"files"];
        if ((fileObjectsList != nil) && [fileObjectsList isKindOfClass:NSArray.class] && (fileObjectsList.count > 0)) {
            // Use the first object in the list
            NSDictionary* fileObject = fileObjectsList.firstObject;

            // Only process images at this point
            if ([fileObject[@"file_attrs"][@"type"] hasPrefix:@"image/"]) {
                hasAttachment = YES;

                __weak typeof(self) weakSelf = self;

                [self describeFile:fileObject[@"file_id"] completion:^(NSError* error, NINFileInfo* fileInfo) {
                    NSLog(@"Found file info: %@", fileInfo);

                    NINChannelMessage* msg = [NINChannelMessage messageWithID:messageID textContent:nil sender:messageUser timestamp:[NSDate dateWithTimeIntervalSince1970:messageTime]  mine:(actionId != 0) attachment:fileInfo];
                    [weakSelf addNewChatMessage:msg];
                }];
            }
        }

        NSString* text = payloadDict[@"text"];

        // Only allocate a new message now if there is text and no attachment
        if (!hasAttachment && (text.length > 0)) {
            NINChannelMessage* msg = [NINChannelMessage messageWithID:messageID textContent:text sender:messageUser timestamp:[NSDate dateWithTimeIntervalSince1970:messageTime] mine:(actionId != 0) attachment:nil];
            [self addNewChatMessage:msg];
        }
    }

    NSLog(@"handleInboundChatMessageWithPayload: returning");
}

-(void) handleInboundMessage:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload actionId:(long)actionId {
    NSError* error = nil;

    NSString* messageID = [params getString:@"message_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* messageType = [params getString:@"message_type" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSLog(@"Got message_type: %@, message_id: %@, actionId: %ld", messageType, messageID, actionId);

    NSString* messageUserID = [params getString:@"message_user_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    double messageTime;
    [params getFloat:@"message_time" val:&messageTime error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NINChannelUser* messageUser = _channelUsers[messageUserID];
    if (messageUser == nil) {
        NSLog(@"Message from unknown user: %@", messageUserID);
        //TODO how big a problem is this?
    }

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

            postNotification(kNINWebRTCSignalNotification, @{@"messageType": messageType, @"payload": payloadDict, @"messageUser": messageUser});
        }
        return;
    }

    if (![messageType isEqualToString:@"ninchat.com/text"] && ![messageType isEqualToString:@"ninchat.com/file"]) {
        // Ignore all but text/file messages
        NSLog(@"Ignoring unsupported message type: '%@'", messageType);
        return;
    }

    // Expect other messages to be chat messages
    [self handleInboundChatMessageWithPayload:payload messageID:messageID messageUser:messageUser messageTime:messageTime actionId:actionId];
}

-(void) messageReceived:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload {
    NSCAssert(self.currentChannelID != nil, @"No active channel");

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

/*
 Event: map[event_id:2 action_id:1 channel_id:5npnrkp1009n error_type:channel_not_found event:error]
 */
-(void) handleError:(NINLowLevelClientProps*)params {
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

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
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
-(void) joinQueueWithId:(NSString*)queueID progress:(queueProgressCallback _Nonnull)progress channelJoined:(emptyBlock _Nonnull)channelJoined {

    NSCAssert(self.session != nil, @"No chat session");
    NSCAssert(self.currentQueueID == nil, @"Already in queue!");
    NSCAssert(self.queueProgressObserver == nil, @"Cannot have observer set already");

    __weak typeof(self) weakSelf = self;

    // This block does the actual operation
    void(^performJoin)(void) = ^() {
        [weakSelf.ninchatSession sdklog:@"Joining queue %@..", queueID];

        weakSelf.channelJoinObserver = fetchNotification(kChannelJoinedNotification, ^BOOL(NSNotification* note) {
            [NSNotificationCenter.defaultCenter removeObserver:weakSelf.queueProgressObserver];
            weakSelf.queueProgressObserver = nil;

            channelJoined();
            return YES;
        });

        NINLowLevelClientProps* params = [NINLowLevelClientProps new];
        [params setString:@"action" val:@"request_audience"];
        [params setString:@"queue_id" val:queueID];

        int64_t actionId;
        NSError* error = nil;
        [weakSelf.session send:params payload:nil actionId:&actionId error:&error];
        if (error != nil) {
            NSLog(@"Error joining queue: %@", error);
            progress(error, -1);
        }

        // Keep listening to progress events for queue position updates
        weakSelf.queueProgressObserver = fetchNotification(kActionNotification, ^(NSNotification* note) {
            NSNumber* eventActionId = note.userInfo[@"action_id"];
            NSString* eventType = note.userInfo[@"event"];
            NSString* queueId = note.userInfo[@"queue_id"];

            if ((eventActionId.longValue == actionId) || ([eventType isEqualToString:@"queue_updated"] && [queueId isEqualToString:queueId])) {
                NSCAssert(weakSelf.currentQueueID != nil, @"Current queue ID must be set by now");

                NSError* error = note.userInfo[@"error"];
                NSInteger queuePosition = [note.userInfo[@"queue_position"] intValue];
                progress(error, queuePosition);
            }

            return NO;
        });
    };

    if (self.currentChannelID != nil) {
        [self.ninchatSession sdklog:@"Parting current channel first"];

        [self partChannel:self.currentChannelID completion:^(NSError* error) {
            [weakSelf.ninchatSession sdklog:@"Channel parted; joining queue."];
            weakSelf.currentChannelID = nil;
            performJoin();
        }];
    } else {
        performJoin();
    }
}

// Leaves the current queue, if any
-(void) leaveCurrentQueueWithCompletionCallback:(callbackWithErrorBlock _Nonnull)completion {
    if (self.currentQueueID == nil) {
        [self.ninchatSession sdklog:@"Error: tried to leave current queue but not in queue currently!"];
        return;
    }

    [self.ninchatSession sdklog:@"Leaving current queue."];

    // Stop the queue observers
    [NSNotificationCenter.defaultCenter removeObserver:self.channelJoinObserver];
    self.channelJoinObserver = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self.queueProgressObserver];
    self.queueProgressObserver = nil;

    //TODO call action delete_user with my current user ID.

    completion(nil);
}

// Retrieves the WebRTC ICE STUN/TURN server details
-(void) beginICEWithCompletionCallback:(beginICECallbackBlock _Nonnull)completion {
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
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
-(int64_t) sendMessageWithMessageType:(NSString*)messageType payloadDict:(NSDictionary*)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion {

    NSCAssert(self.session != nil, @"No chat session");

    if (self.currentChannelID == nil) {
        completion(newError(@"No active channel"));
        return -1;
    }

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"send_message"];
    [params setString:@"message_type" val:messageType];
    [params setString:@"channel_id" val:self.currentChannelID];

    if ([messageType isEqualToString:@"ninchat.com/metadata"] && payloadDict[@"data"][@"rating"] != nil) {
        NSLog(@"Sending ratings, adding extra params to make message pass on closed channel");
        [params setStringArray:@"message_recipient_ids" ref:[NINLowLevelClientStrings new]];
        [params setBool:@"message_fold" val:YES];
    }

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

    NINLowLevelClientPayload* payload = [NINLowLevelClientPayload new];
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

-(void) sendFile:(NSString*)fileName withData:(NSData*)data completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.session != nil, @"No chat session");

    if (self.currentChannelID == nil) {
        completion(newError(@"No active channel"));
        return;
    }

    NINLowLevelClientProps* fileAttributes = [NINLowLevelClientProps new];
    [fileAttributes setString:@"name" val:fileName];

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"send_file"];
    [params setObject:@"file_attrs" ref:fileAttributes];
    [params setString:@"channel_id" val:self.currentChannelID];

    NINLowLevelClientPayload* payload = [NINLowLevelClientPayload new];
    [payload append:data];

    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:payload actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error sending file: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) partChannel:(NSString*)channelID completion:(callbackWithErrorBlock _Nonnull)completion {
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"part_channel"];
    [params setString:@"channel_id" val:channelID];

    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error parting channel: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) disconnect {
    [self.ninchatSession sdklog:@"disconnect: Closing Ninchat session."];

    self.currentChannelID = nil;
    self.currentQueueID = nil;

    [self.session close];
    self.session = nil;
}

// Low-level shutdown of the chatsession; invalidates session resource.
-(void) closeChat {
    NSLog(@"Shutting down chat Session..");

    [self disconnect];

    // Signal the delegate that our session has ended
    [self.ninchatSession.delegate ninchatDidEndSession:self.ninchatSession];
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

    [self.ninchatSession sdklog:@"Opening new chat session."];

    // Make sure our site configuration contains a realm_id
    NSString* realmId = self.siteConfiguration[@"default"][@"audienceRealmId"];
    if ((realmId == nil) || (![realmId isKindOfClass:[NSString class]])) {
        return newError(@"Could not find valid realm id in the site configuration");
    }

    self.realmId = realmId;

    NINLowLevelClientStrings* messageTypes = [NINLowLevelClientStrings new];
    [messageTypes append:@"ninchat.com/*"];

    NINLowLevelClientProps* sessionParams = [NINLowLevelClientProps new];
    if (self.siteSecret != nil) {
        [sessionParams setString:@"site_secret" val:self.siteSecret];
    }

    // Get the username from the site config
    NSString* userName = self.siteConfiguration[@"default"][@"userName"];
    if (userName != nil) {
        NINLowLevelClientProps* attrs = [NINLowLevelClientProps new];
        [attrs setString:@"name" val:userName];
        [sessionParams setObject:@"user_attrs" ref:attrs];
    }

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

    SessionCallbackHandler* callbackHandler = [SessionCallbackHandler new];
    callbackHandler.sessionManager = self;

    self.session = [NINLowLevelClientSession new];
    [self.session setAddress:kNinchatServerHostName];
    [self.session setOnClose:callbackHandler];
    [self.session setOnConnState:callbackHandler];
    [self.session setOnLog:callbackHandler];
    [self.session setOnSessionEvent:callbackHandler];
    [self.session setOnEvent:callbackHandler];

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

    return nil;
}

-(NSString*) translation:(NSString*)keyName formatParams:(NSDictionary<NSString*,NSString*>*)formatParams {
    // Look for a translation. If one is not available for this key, use the key itself.
    NSString* translation = self.siteConfiguration[@"default"][@"translations"][keyName];
    if (translation == nil) {
        translation = keyName;
    }

    for (NSString* formatKey in formatParams.allKeys) {
        NSString* formatValue = formatParams[formatKey];
        translation = [translation stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{{%@}}", formatKey] withString:formatValue];
    }

    return translation;
}

#pragma mark - 

-(void) onEvent:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload lastReply:(BOOL)lastReply {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

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
    } else if ([event isEqualToString:@"file_found"]) {
        [self fileFound:params];
    } else if ([event isEqualToString:@"channel_parted"]) {
        [self channelParted:params];
    }

    // Forward the event to the SDK delegate
    if ([self.ninchatSession.delegate respondsToSelector:@selector(ninchat:onLowLevelEvent:payload:lastReply:)]) {
        [self.ninchatSession.delegate ninchat:self.ninchatSession onLowLevelEvent:params payload:payload lastReply:lastReply];
    }
}

-(void) onLog:(NSString*)msg {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSLog(@"Log: %@", msg);
}

-(void) onConnState:(NSString*)state {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSLog(@"Connection state: %@", state);
}

-(void) onClose {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSLog(@"Session closed.");
}

-(void) onSessionEvent:(NINLowLevelClientProps*)params {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSLog(@"Session event: %@", [params string]);

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    if ([event isEqualToString:@"session_created"]) {
        postNotification(kActionNotification, @{@"event_type": event});
    }
}

#pragma mark - Lifecycle etc.

-(void) dealloc {
    [self disconnect];

    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

-(id) init {
    self = [super init];

    if (self != nil) {
        _queues = [NSMutableArray array];
        _chatMessages = [NSMutableArray array];
        _channelUsers = [NSMutableDictionary dictionary];
    }

    return self;
}

@end

#pragma mark - SessionCallbackHandler

@implementation SessionCallbackHandler

-(void) onEvent:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload lastReply:(BOOL)lastReply {
    runOnMainThread(^{
        [self.sessionManager onEvent:params payload:payload lastReply:lastReply];
    });
}

-(void) onClose {
    runOnMainThread(^{
        [self.sessionManager onClose];
    });
}

-(void) onSessionEvent:(NINLowLevelClientProps*)params {
    runOnMainThread(^{
        [self.sessionManager onSessionEvent:params];
    });
}

-(void) onLog:(NSString*)msg {
    runOnMainThread(^{
        [self.sessionManager onLog:msg];
    });
}

-(void) onConnState:(NSString*)state {
    runOnMainThread(^{
        [self.sessionManager onConnState:state];
    });
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end


