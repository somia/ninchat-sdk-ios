//
//  NINMessagesViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINChat;

@interface NINMessagesViewController : UIViewController

/** Reference to the NINChat instance that allocated this controller. */
@property (nonatomic, strong) NINChat* chat;

@end
