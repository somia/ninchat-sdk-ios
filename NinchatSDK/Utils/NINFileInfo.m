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
//@property (nonatomic, assign) NSInteger width;
//@property (nonatomic, assign) NSInteger height;

@end

@implementation NINFileInfo

-(NSString*) description {
    return [NSString stringWithFormat:@"ID: %@, mimeType: %@, size: %ld", self.fileID, self.mimeType, self.size];
}

+(instancetype) imageFileInfoWithID:(NSString*)fileID mimeType:(NSString*)mimeType size:(NSInteger)size url:(NSString*)url urlExpiry:(NSDate*)urlExpiry {
    NINFileInfo* info = [NINFileInfo new];
    info.fileID = fileID;
    info.mimeType = mimeType;
    info.size = size;
    info.url = url;
    info.urlExpiry = urlExpiry;
//    info.width = width;
//    info.height = height;

    return info;
}

@end
