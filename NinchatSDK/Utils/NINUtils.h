//
//  Utils.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#ifndef NINUtils_h
#define NINUtils_h

#import "NINPrivateTypes.h"

// Server host name.
extern NSString* _Nonnull const kNinchatServerHostName;

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

/** Util method for creating a constraint that matches given attribute exactly between two views. */
NSLayoutConstraint* _Nonnull constraint(UIView* _Nonnull view1, UIView* _Nonnull view2, NSLayoutAttribute attr);

/** Returns the resource bundle containing the requested resource. */
NSBundle* _Nonnull findResourceBundle(void);

/** Asynchronously retrieves the site configuration from the server over HTTPS. */
void fetchSiteConfig(NSString* _Nonnull configurationKey, fetchSiteConfigCallbackBlock _Nonnull callbackBlock);

#endif /* NINUtils_h */
