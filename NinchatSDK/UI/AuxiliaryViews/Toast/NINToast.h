//
//  NINToast.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@interface NINToast : UIView

/** Shows the toast for a while. Callback (if defined) is called when the toast has disappeared. */
+(void) showWithMessage:(NSString*)message callback:(emptyBlock)callback;

@end
