//
//  NINComposeInputView.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINSessionManager.h"
#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

/** Represents the ui/compose message UI within a NINChatBubbleCell. */
@interface NINComposeInputView : UIView

-(void) clear;
-(void) populateWithLabel:(NSString*)label options:(NSArray<NSDictionary*>*)options siteConfiguration:(NSDictionary*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets;

@end

