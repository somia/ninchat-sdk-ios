//
//  NINCloseChatButton.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@interface NINCloseChatButton : UIView

@property (nonatomic, copy) emptyBlock pressedCallback;

@end

/** Storyboard/xib-embeddable subclass of NINCloseChatButton */
@interface NINEmbeddableCloseChatButton : NINCloseChatButton

@end
