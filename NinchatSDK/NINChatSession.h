//
//  NINClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

#import "NINPublicTypes.h"

@class NINChatSession;

/**
 * Delegate protocol for NINChatSession class.
 */
@protocol NINChatSessionDelegate <NSObject>

/**
 * Implemeent this if you want to receive debug/error logging from the SDK.
 */
@optional
-(void) ninchat:(NINChatSession*)session didOutputSDKLog:(NSString* _Nonnull)message;

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

/**
 * Delegate object for receiving asynchronous callbacks from the SDK.
 */
@property (nonatomic, weak, nullable) id<NINChatSessionDelegate> delegate;

/**
 * Initializes the API.
 */
-(id _Nonnull) initWithConfigurationKey:(NSString* _Nonnull)configurationKey siteSecret:(NSString* _Nullable)siteSecret;

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
