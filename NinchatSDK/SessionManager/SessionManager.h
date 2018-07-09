//
//  SessionManager.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PublicTypes.h"

@class ChannelMessage;

/**
 This class takes care of the chat session and all related state.
 */
@interface SessionManager : NSObject

//TODO check if all of these are needed ..
@property (nonatomic, strong) NSString* _Nullable configKey;
@property (nonatomic, strong) NSString* _Nullable queueId;
@property (nonatomic, strong) NSString* _Nullable userName;
@property (nonatomic, strong) NSString* _Nullable audienceMetadataJSON;
@property (nonatomic, strong) NSString* _Nullable lang;

/** Realm ID to use. */
@property (nonatomic, strong) NSString* _Nonnull realmId;

/**
 * Chronological list of messages on the current channel. The list is ordered by the message
 * timestamp in decending order (most recent first).
 */
@property (nonatomic, strong, readonly) NSArray<ChannelMessage*>* _Nonnull channelMessages;

/** Opens the session with an asynchronous completion callback. */
-(NSError*_Nonnull) openSession:(startCallbackBlock _Nonnull)callbackBlock;

/** Joins a channel with the given id. */
-(void) joinChannelWithId:(NSString* _Nonnull)channelId completion:(void (^_Nonnull)(NSError* _Nonnull))completion;

/** Sends chat message to the active chat channel. */
-(void) sendMessage:(NSString* _Nonnull)message completion:(void (^_Nonnull)(NSError* _Nonnull))completion;

@end
