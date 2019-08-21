//
//  NINComposeInputView.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINSessionManager.h"
#import "NINUIComposeMessage.h"
#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

/** Represents the ui/compose message UI within a NINChatBubbleCell. */
@interface NINComposeInputView : UIView

/** Compose message as a dictionary, including current selection status. */
@property (nonatomic, strong, readonly) NSDictionary* composeMessageDict;

/** Send button callback. */
@property (nonatomic, copy) void (^uiComposeSendPressedCallback)(NINComposeInputView*);

-(void) clear;
-(void) populateWithComposeMessage:(NINUIComposeMessage*)message siteConfiguration:(NSDictionary*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets;

/** Set send button appearance to initial state in response to send failing; also called in initialisation. */
-(void) sendActionFailed;

@end

