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

// Notifications emitted by this class.
extern NSString* _Nonnull const kChannelClosedNotification;

/**
 This class takes care of the chat session and all related state.
 */
@interface NINSessionManager : NSObject

//TODO check if all of these are needed ..
//@property (nonatomic, strong) NSString* _Nullable configKey;
//@property (nonatomic, strong) NSString* _Nullable queueId;
//@property (nonatomic, strong) NSString* _Nullable userName;
//@property (nonatomic, strong) NSString* _Nullable audienceMetadataJSON;
//@property (nonatomic, strong) NSString* _Nullable lang;

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
-(void) joinQueueWithId:(NSString*)queueId completion:(callbackWithErrorBlock _Nonnull)completion channelJoined:(emptyBlock _Nonnull)channelJoined;

/** Joins a channel with the given id. */
//-(void) joinChannelWithId:(NSString* _Nonnull)channelId completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends chat message to the active chat channel. */
-(void) sendMessage:(NSString* _Nonnull)message completion:(callbackWithErrorBlock _Nonnull)completion;

@end
