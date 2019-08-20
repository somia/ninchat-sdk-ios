//
//  NINComposeInputView.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

@interface NINComposeInputView : UIView

-(void) clear;
-(void) populateWithLabel:(NSString*)label options:(NSArray<NSDictionary*>*)options colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets;


@end

