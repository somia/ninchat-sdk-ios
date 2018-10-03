//
//  UIButton+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 03/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINChatSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (Ninchat)

-(void) overrideImageWithSession:(NINChatSession*)session assetKey:(NINImageAssetKey)assetKey;

@end

NS_ASSUME_NONNULL_END
