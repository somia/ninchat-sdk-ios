//
//  NINClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

@import NinchatLowLevelClient;

#import "NINPublicTypes.h"

// Forward declarations
@class NINChatSession;

// Image asset keys
typedef NSString* const NINImageAssetKey NS_STRING_ENUM;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyQueueViewProgressIndicator;

/**
 * Delegate protocol for NINChatSession class. All the methods are called on
 * the main thread.
 */
@protocol NINChatSessionDelegate <NSObject>

/**
 * Implemeent this if you want to receive debug/error logging from the SDK.
 */
@optional
-(void) ninchat:(NINChatSession*_Nonnull)session didOutputSDKLog:(NSString* _Nonnull)message;

/**
 * Exposes the low-level events. See the Ninchat API specification for more info.
 */
@optional
-(void) ninchat:(NINChatSession*_Nonnull)session onLowLevelEvent:(NINLowLevelClientProps*_Nonnull)params payload:(NINLowLevelClientPayload*_Nonnull)payload lastReply:(BOOL)lastReply;

/**
 * This method allows the SDK delegate to override image assets used in the
 * SDK UI. If the implementation does not wish to override an asset, nil should
 * be returned.
 *
 * For available asset key strings, see documentation.
 */
-(UIImage* _Nullable) ninchat:(NINChatSession*_Nonnull)session overrideImageAssetForKey:(NINImageAssetKey _Nonnull)assetKey;

/**
 * Indicates that the Ninchat SDK UI has completed its chat. and would like
 * to be closed. The API caller should remove the Ninchat SDK UI from
 * its view hierarchy.
 */
-(void) ninchatDidEndSession:(NINChatSession* _Nonnull)ninchat;

@end

/**
 * Ninchat chat session. Instantiate with the dedicated initializer
 * -initWithConfigurationKey:siteSecret:.
 *
 * Create a new session for each chat session; UI component(s) returned by
 * the chat session are not recycleable either.
 */
@interface NINChatSession : NSObject

/** Exposes the low-level chat session interface. Only available after startWithCallback: has been called. */
@property (nonatomic, strong, readonly) NINLowLevelClientSession* _Nonnull session;

/**
 * Delegate object for receiving asynchronous callbacks from the SDK.
 */
@property (nonatomic, weak, nullable) id<NINChatSessionDelegate> delegate;

/**
 * Initializes the API.
 *
 * @param serverAddress server address as host[:port]
 * @param configurationKey configuration key; this decides the chat realm
 * @param siteSecret optional secret for fetching the site configuration. Can be nil if not needed.
 * @param queueID ID of the queue to join automatically. Nil to not join automatically to a queue.
 * @return new API facade instance
 */
-(id _Nonnull) initWithServerAddress:(NSString*_Nonnull)serverAddress configurationKey:(NSString* _Nonnull)configurationKey siteSecret:(NSString* _Nullable)siteSecret queueID:(NSString* _Nullable)queueID;

/**
 * Starts the API engine. Must be called before other API methods. The caller
 * must wait for the callback block to be called without errors.
 */
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock;

/**
 * Returns the view controller for the Ninchat UI.
 */
-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController;

@end
