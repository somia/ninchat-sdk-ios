//
//  NINFileInfo.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 17/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import "NINPrivateTypes.h"

typedef void (^updateFileInfoCallback)(NSError* _Nullable error, BOOL didNetworkRefresh);

@class NINSessionManager;

/** Describes a downloadable file with ID, mime type, size and url. */
@interface NINFileInfo : NSObject

@property (nonatomic, strong, readonly) NSString* fileID;
@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSString* mimeType;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, strong, readonly) NSString* url;
@property (nonatomic, strong, readonly) NSDate* urlExpiry;

// These only apply to images / videos (from their thumbnails)
@property (nonatomic, assign) CGFloat aspectRatio; // width : height

/** Constructs a new file info. */
+(instancetype) fileWithSessionManager:(NINSessionManager*)sessionManager fileID:(NSString*)fileID name:(NSString*)name mimeType:(NSString*)mimeType size:(NSInteger)size;

/** Calls describe_file to retrieve / refresh file info (including the temporary URL). */
-(void) updateInfoWithCompletionCallback:(updateFileInfoCallback)completion;

/** Whether or not this file represents an image. */
-(BOOL) isImage;

/** Whether or not this file represents a video. */
-(BOOL) isVideo;

/** Whether this file is an image or video file. */
-(BOOL) isImageOrVideo;

-(BOOL) isPDF;

@end
