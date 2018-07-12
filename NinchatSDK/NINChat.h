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

/**
 * API Facade for Ninchat iOS SDK.
 */
@interface NINChat : NSObject

//@property (nonatomic, assign) id <NINChatStatusDelegate> statusDelegate;

/**
 * Initializes the API.
 */
-(id _Nonnull) initWithConfigurationKey:(NSString* _Nonnull)configurationKey;

/**
 * Starts the API engine. Must be called before other API methods. The caller
 * must wait for the callback block to be called without errors.
 */
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock;

/**
 * Returns the view controller for the Ninchat UI.
 */
-(nonnull UIViewController*) viewController;

@end
