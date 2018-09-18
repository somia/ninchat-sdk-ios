//
//  NINFileInfo.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 17/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Describes a downloadable file with ID, mime type, size and url. */
@interface NINFileInfo : NSObject

@property (nonatomic, strong, readonly) NSString* fileID;
@property (nonatomic, strong, readonly) NSString* mimeType;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, strong, readonly) NSString* url;
@property (nonatomic, strong, readonly) NSDate* urlExpiry;

// These only apply to images
@property (nonatomic, assign, readonly) CGFloat aspectRatio; // width : height
//@property (nonatomic, assign, readonly) NSInteger width;
//@property (nonatomic, assign, readonly) NSInteger height;

/** Constructs a new file info. */
+(instancetype) imageFileInfoWithID:(NSString*)fileID mimeType:(NSString*)mimeType size:(NSInteger)size url:(NSString*)url urlExpiry:(NSDate*)urlExpiry aspectRatio:(CGFloat)aspectRatio;

/** Whether or not this file represents an image. */
-(BOOL) isImage;

@end
