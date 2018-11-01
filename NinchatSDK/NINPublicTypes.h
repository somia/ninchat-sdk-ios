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
typedef void (^startCallbackBlock)(NSError* _Nullable error);

/** Defines the type for a overrideable color asset. */
typedef NSString* const NINImageAssetKey NS_STRING_ENUM;

// Image asset keys
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyQueueViewProgressIndicator;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatUserTypingIndicator;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyInitialViewJoinQueueButton;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyInitialViewCloseWindowButton;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatViewBackgroundTexture;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyCloseChatButton;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatBubbleLeft;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatBubbleLeftSeries;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatBubbleRight;
FOUNDATION_EXPORT NINImageAssetKey _Nonnull NINImageAssetKeyChatBubbleRightSeries;

/** Defines the type for a overrideable color asset. */
typedef NSString* const NINColorAssetKey NS_STRING_ENUM;

// Color asset keys
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyButtonPrimaryText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyButtonSecondaryText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyInfoText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatName;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatTimestamp;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatBubbleLeftText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatBubbleRightText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyTextareaText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyTextareaSubmitText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatBubbleLeftLink;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyChatBubbleRightLink;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyModalBackground;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetKeyModalText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetBackgroundTop;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetTextTop;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetLink;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetBackgroundBottom;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetTextBottom;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetRatingPositiveText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetRatingNeutralText;
FOUNDATION_EXPORT NINColorAssetKey _Nonnull NINColorAssetRatingNegativeText;

#endif /* PublicTypes_h */
