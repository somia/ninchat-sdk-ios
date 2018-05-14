//
//  NINClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

/**
 * API Facade for Ninchat iOS SDK.
 *
 * Instantiate this class using the `create` method.
 */
@interface NINChat : NSObject

/** Initializes the client. Always the create the client with this method. */
+(instancetype) create;

/** Returns the initial view controller for the Ninchat UI. */
-(UIViewController*) initialViewController;

/** Tests the connectivity. Returns YES if successful. */
-(BOOL) connectionTest;

@end
