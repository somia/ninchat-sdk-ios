//
//  NINFileInfo.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 17/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINFileInfo.h"

@interface NINFileInfo ()

// Writable versions of properties
@property (nonatomic, strong) NSString* fileID;
@property (nonatomic, strong) NSString* mimeType;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSDate* urlExpiry;

// These only apply to images
@property (nonatomic, assign) CGFloat aspectRatio;

@end

@implementation NINFileInfo

-(NSString*) description {
    return [NSString stringWithFormat:@"ID: %@, mimeType: %@, size: %ld", self.fileID, self.mimeType, (long)self.size];
}

-(BOOL) isImage {
    return [self.mimeType hasPrefix:@"image/"];
}

+(instancetype) imageFileInfoWithID:(NSString*)fileID mimeType:(NSString*)mimeType size:(NSInteger)size url:(NSString*)url urlExpiry:(NSDate*)urlExpiry aspectRatio:(CGFloat)aspectRatio {
    NINFileInfo* info = [NINFileInfo new];
    info.fileID = fileID;
    info.mimeType = mimeType;
    info.size = size;
    info.url = url;
    info.urlExpiry = urlExpiry;
    info.aspectRatio = aspectRatio;

    return info;
}

@end
