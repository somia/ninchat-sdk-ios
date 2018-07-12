//
//  PrivateTypes.h
//  Pods
//
//  Created by Matti Dahlbom on 08/07/2018.
//

#ifndef PrivateTypes_h
#define PrivateTypes_h

typedef void (^emptyBlock)(void);
typedef void (^callbackWithErrorBlock)(NSError* _Nullable);
typedef BOOL (^notificationBlock)(NSNotification* _Nonnull);
typedef void (^fetchSiteConfigCallbackBlock)(NSDictionary* _Nullable, NSError* _Nullable);

/**
 * Notification name for 'new message' notification. Userinfo param 'message'
 * contains a ChannelMessage* object.
 */
extern NSString* _Nonnull const kNewChannelMessageNotification;

#endif /* PrivateTypes_h */
