//
//  Utils.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

typedef void (^emptyBlock)(void);
typedef BOOL (^notificationBlock)(NSNotification* _Nonnull);

/**
 Runs the given block on the main thread (queue).
 */
void runOnMainThread(emptyBlock _Nonnull block);

/**
 Posts a named notification, using the default notification center instance,
 with given user info data on the main thread.
 */
void postNotification(NSString* notificationName, NSDictionary* userInfo);

/**
 Listens to a given notification name on the queue (thread) which posts the
 notification. It then calls the block parameter; if this block returns YES,
 removes the observer. If the block returns NO, it keeps listening.
 */
void fetchNotification(NSString* notificationName, notificationBlock _Nonnull block);

/** Creates a new NSError with a message. */
NSError* newError(NSString* msg);

#endif /* Utils_h */
