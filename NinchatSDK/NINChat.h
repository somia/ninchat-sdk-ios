//
//  NINClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

@protocol NINChatStatusDelegate<NSObject>

@required
-(void) statusDidChange:(NSString*)status;

@end

/**
 * API Facade for Ninchat iOS SDK.
 */
@interface NINChat : NSObject

@property (nonatomic, strong) NSString* configKey;
@property (nonatomic, strong) NSString* queueId;
@property (nonatomic, strong) NSString* userName;
@property (nonatomic, strong) NSString* audienceMetadataJSON;
@property (nonatomic, strong) NSString* lang;
@property (nonatomic, assign) id <NINChatStatusDelegate> statusDelegate;

/** Returns the view controller for the Ninchat UI. */
-(nonnull UIViewController*) viewController;

//TODO: anything below here belong into a private API - SessionManager

/** Joins a channel with the given id. */
-(void) joinChannelWithId:(NSString*)channelId completion:(void (^)(NSError*))completion;

/** Sends chat message to the active chat channel. */
-(void) sendMessage:(NSString*)message completion:(void (^)(NSError*))completion;

/** Starts the chat. Returns YES if successful. */
-(BOOL) start;

@end
