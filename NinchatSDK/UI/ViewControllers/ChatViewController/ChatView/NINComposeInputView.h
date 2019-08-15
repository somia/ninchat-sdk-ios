//
//  NINComposeInputView.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NINComposeInputView : UIView

-(void) clear;
-(void) populateWithLabel:(NSString*)label options:(NSArray<NSString*>*)options;


@end

