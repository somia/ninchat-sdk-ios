//
//  NINSessionManager+Internal.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatSession+Internal.h"

@implementation NINChatSession (Internal)

-(void) sdklog:(NSString*)format, ... {
    if ([self.delegate respondsToSelector:@selector(ninchat:didOutputSDKLog:)]) {
        va_list args;
        va_start(args, format);
        [self.delegate ninchat:self didOutputSDKLog:[[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
    }
}

-(UIImage*) overrideImageAssetForKey:(NINImageAssetKey)assetKey {
    if ([self.delegate respondsToSelector:@selector(ninchat:overrideImageAssetForKey:)]) {
        return [self.delegate ninchat:self overrideImageAssetForKey:assetKey];
    } else {
        return nil;
    }
}

-(UIColor* _Nullable) overrideColorAssetForKey:(NINColorAssetKey _Nonnull)assetKey {
    if ([self.delegate respondsToSelector:@selector(ninchat:overrideColorAssetForKey:)]) {
        return [self.delegate ninchat:self overrideColorAssetForKey:assetKey];
    } else {
        return nil;
    }
}

@end
