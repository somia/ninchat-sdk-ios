//
//  UIButton+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 03/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "UIButton+Ninchat.h"
#import "NINChatSession+Internal.h"

@implementation UIButton (Ninchat)

-(void) overrideImageWithSession:(NINChatSession*)session assetKey:(NINImageAssetKey)assetKey {
    UIImage* overrideImage = [session overrideImageAssetForKey:assetKey];

    if (overrideImage != nil) {
        [self setBackgroundImage:overrideImage forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 0;
        self.layer.borderWidth = 0;
    }
}

@end
