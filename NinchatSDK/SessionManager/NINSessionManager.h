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

@class NINQueue;
@class NINChannelMessage;
@class NINChatSession;

// Notifications emitted by this class.
extern NSString* _Nonnull const kChannelClosedNotification;

/**
 This class takes care of the chat session and all related state.
 */
@interface NINSessionManager : NSObject

/** (Circular) Reference to the session object that created this session manager. */
@property (nonatomic, weak, nullable) NINChatSession* ninchatSession;

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
-(void) joinQueueWithId:(NSString* _Nonnull)queueId completion:(callbackWithErrorBlock _Nonnull)completion channelJoined:(emptyBlock _Nonnull)channelJoined;

/** Runs ICE (Interactive Connectivity Establishment) for WebRTC connection negotiations. */
-(void) beginICEWithCompletion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends chat message to the active chat channel. */
-(void) sendTextMessage:(NSString* _Nonnull)message completion:(callbackWithErrorBlock _Nonnull)completion;

/** Closes the chat by shutting down the session. Triggers the API delegate method -ninchatDidEndChatSession:. */
-(void) closeChat;

/** (Optionally) sends ratings and finishes the current chat from our end. */
-(void) finishChat:(NSNumber* _Nullable)rating;

@end
