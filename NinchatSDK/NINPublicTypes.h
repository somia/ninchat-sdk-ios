//
//  PublicTypes.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#ifndef PublicTypes_h
#define PublicTypes_h

/** Asynchronous completion callback for the -start operation. */
typedef void (^startCallbackBlock)(NSError* error);

// Image asset keys
typedef NSString* const NINImageAssetKey NS_STRING_ENUM;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyQueueViewProgressIndicator;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatUserTypingIndicator;

#endif /* PublicTypes_h */
