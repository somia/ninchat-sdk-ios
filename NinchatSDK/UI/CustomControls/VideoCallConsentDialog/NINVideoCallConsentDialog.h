//
//  NINVideoCallConsentDialog.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINChannelUser;
@class NINSessionManager;

typedef NS_ENUM(NSInteger, NINConsentDialogResult) {
    NINConsentDialogResultAccepted,
    NINConsentDialogResultRejected
};

typedef void (^consentDialogClosedBlock)(NINConsentDialogResult result);

/**
 * This view provides a mechanism for asking the mobile user whether
 * he/she would accept an incoming video call.
 */
@interface NINVideoCallConsentDialog : UIView

/** Displays the dialog on top of another view. */
+(instancetype _Nonnull) showOnView:(UIView* _Nonnull)view forRemoteUser:(NINChannelUser* _Nullable)user sessionManager:(NINSessionManager* _Nonnull)sessionManager closedBlock:(consentDialogClosedBlock _Nullable)closedBlock;

@end
