//
//  NINChatMetaCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@class NINChatMetaMessage;

@interface NINChatMetaCell : UITableViewCell

@property (nonatomic, copy) emptyBlock closeChatCallback;

-(void) populateWithMessage:(NINChatMetaMessage*)message;

@end
