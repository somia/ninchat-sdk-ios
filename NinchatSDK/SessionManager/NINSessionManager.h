//
//  SessionManager.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"
#import "NINChatSession+Internal.h" // To provide log: method

@class NINQueue;
@class NINChannelMessage;
@class NINChatSession;
@class ClientSession;

/** Notification that indicates the current channel was closed. */
extern NSString* _Nonnull const kNINChannelClosedNotification;

/**
 * Notification that indicates a WebRTC signaling message was received.
 * Userinfo 'messageType' contains a kNINMessageTypeWebRTC* value, 'payload'
 * contains the message payload.
 */
extern NSString* _Nonnull const kNINWebRTCSignalNotification;

/** Message type for WebRTC signaling: 'ICE candidate' */
extern NSString* _Nonnull const kNINMessageTypeWebRTCIceCandidate;

/** Message type for WebRTC signaling: 'answer'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCAnswer;

/** Message type for WebRTC signaling: 'offer'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCOffer;

/** Message type for WebRTC signaling: 'call'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCCall;

/** Message type for WebRTC signaling: 'pick up'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCPickup;

/** Message type for WebRTC signaling: 'hang up'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCHangup;

/**
 This class takes care of the chat session and all related state.
 */
@interface NINSessionManager : NSObject

/** (Circular) Reference to the session object that created this session manager. */
@property (nonatomic, weak) NINChatSession* ninchatSession;

/** Low-level chat session reference. */
@property (nonatomic, strong, readonly) ClientSession* session;

/** Configuration key; used to retrieve service configuration (site config) */
@property (nonatomic, strong) NSString* _Nonnull configurationKey;

/** Site secret; used to authenticate to eg. test servers. */
@property (nonatomic, strong) NSString* _Nullable siteSecret; 

/** Site configuration. */
@property (nonatomic, strong) NSDictionary* _Nonnull siteConfiguration;

/** List of available queues for the realm_id. */
@property (nonatomic, strong) NSArray<NINQueue*>* _Nonnull queues;

/**
 * Chronological list of messages on the current channel. The list is ordered by the message
 * timestamp in decending order (most recent first).
 */
@property (nonatomic, strong, readonly) NSArray<NINChannelMessage*>* _Nonnull channelMessages;

/** Opens the session with an asynchronous completion callback. */
-(NSError*_Nonnull) openSession:(startCallbackBlock _Nonnull)callbackBlock;

/** Lists all the available queues for this realm. */
-(void) listQueuesWithCompletion:(callbackWithErrorBlock _Nonnull)completion;

/** Joins a chat queue. */
-(void) joinQueueWithId:(NSString* _Nonnull)queueId progress:(queueProgressCallback _Nonnull)progress channelJoined:(emptyBlock _Nonnull)channelJoined;

/** Leaves the current queue. */
-(void) leaveCurrentQueueWithCompletionCallback:(callbackWithErrorBlock _Nonnull)completion;

/** Runs ICE (Interactive Connectivity Establishment) for WebRTC connection negotiations. */
-(void) beginICEWithCompletionCallback:(beginICECallbackBlock _Nonnull)completion;

/** Sends a message to the activa channel. Active channel must exist. */
-(long) sendMessageWithMessageType:(NSString* _Nonnull)messageType payloadDict:(NSDictionary* _Nonnull)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends chat message to the active chat channel. */
-(void) sendTextMessage:(NSString* _Nonnull)message completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends a file to the chat. */
-(void) sendFile:(NSString*)fileName withData:(NSData*)data completion:(callbackWithErrorBlock _Nonnull)completion;

/** Closes the chat by shutting down the session. Triggers the API delegate method -ninchatDidEndChatSession:. */
-(void) closeChat;

/** (Optionally) sends ratings and finishes the current chat from our end. */
-(void) finishChat:(NSNumber* _Nullable)rating;

/**
 * Get a formatted translation from the site configuration.
 * @param formatParams contains format param mappings key -> value
 */
-(NSString*) translation:(NSString*)keyName formatParams:(NSDictionary<NSString*,NSString*>*)formatParams;

@end
