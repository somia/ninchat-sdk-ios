//
//  Utils.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#ifndef NINUtils_h
#define NINUtils_h

#import "PrivateTypes.h"

/**
 * Runs the given block on the main thread (queue).
 */
void runOnMainThread(emptyBlock _Nonnull block);

/**
 * Posts a named notification, using the default notification center instance,
 * with given user info data on the main thread.
 */
void postNotification(NSString* _Nonnull notificationName, NSDictionary* _Nonnull userInfo);

/**
 * Listens to a given notification name on the queue (thread) which posts the
 * notification. It then calls the block parameter; if this block returns YES,
 * removes the observer. If the block returns NO, it keeps listening.
 *
 * @returns observer handle
 */
id _Nonnull fetchNotification(NSString* _Nonnull notificationName, notificationBlock _Nonnull block);

/** Creates a new NSError with a message. */
NSError* _Nonnull newError(NSString* _Nonnull msg);

/** Returns the resource bundle containing the requested resource. */
NSBundle* _Nonnull findResourceBundle(Class _Nonnull class, NSString* _Nonnull resourceName, NSString* _Nonnull resourceType);

#endif /* NINUtils_h */