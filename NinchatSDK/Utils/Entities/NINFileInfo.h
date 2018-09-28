//
//  NINFileInfo.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 17/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import "NINPrivateTypes.h"

@class NINSessionManager;

/** Describes a downloadable file with ID, mime type, size and url. */
@interface NINFileInfo : NSObject

@property (nonatomic, strong, readonly) NSString* fileID;
@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSString* mimeType;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, strong, readonly) NSString* url;
@property (nonatomic, strong, readonly) NSDate* urlExpiry;

// These only apply to images
@property (nonatomic, assign, readonly) CGFloat aspectRatio; // width : height

/** Constructs a new file info. */
//+(instancetype) imageFileInfoWithID:(NSString*)fileID name:(NSString*)name mimeType:(NSString*)mimeType size:(NSInteger)size url:(NSString*)url urlExpiry:(NSDate*)urlExpiry aspectRatio:(CGFloat)aspectRatio;

/** Constructs a new file info. */
+(instancetype) fileWithSessionManager:(NINSessionManager*)sessionManager fileID:(NSString*)fileID name:(NSString*)name mimeType:(NSString*)mimeType size:(NSInteger)size;

/** Calls describe_file to retrieve / refresh file info (including the temporary URL). */
-(void) updateInfoWithCompletionCallback:(callbackWithErrorBlock)completion;

/** Whether or not this file represents an image. */
-(BOOL) isImage;

/** Whether or not this file represents a video. */
-(BOOL) isVideo;

-(BOOL) isPDF;

@end
