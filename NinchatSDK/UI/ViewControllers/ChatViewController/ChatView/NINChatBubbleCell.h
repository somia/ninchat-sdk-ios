//
//  NINChatBubbleCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

@class NINChannelMessage;
@class NINUserTypingMessage;
@class NINFileInfo;
@class NINVideoThumbnailManager;
@class NINAvatarConfig;

typedef void (^imagePressedCallback)(NINFileInfo* attachment, UIImage* image);

/** Rerepsents a chat message (in a 'bubble') in the chat view. */
@interface NINChatBubbleCell : UITableViewCell

@property (nonatomic, strong) NINVideoThumbnailManager* videoThumbnailManager;
@property (nonatomic, copy) imagePressedCallback imagePressedCallback;
@property (nonatomic, copy) emptyBlock cellConstraintsUpdatedCallback;

-(void) populateWithChannelMessage:(NINChannelMessage*)message imageAssets:(NSDictionary<NINImageAssetKey, UIImage*>*)imageAssets colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets agentAvatarConfig:(NINAvatarConfig*)agentAvatarConfig userAvatarConfig:(NINAvatarConfig*)userAvatarConfig;

-(void) populateWithUserTypingMessage:(NINUserTypingMessage*)message imageAssets:(NSDictionary<NINImageAssetKey, UIImage*>*)imageAssets colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets agentAvatarConfig:(NINAvatarConfig*)agentAvatarConfig;

@end
