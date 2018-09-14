//
//  NINSessionManager+Internal.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatSession.h"

@interface NINChatSession (Internal)

/** Outputs SDK log entry if the delegate is set and defines the log method. */
-(void) sdklog:(NSString*_Nonnull)format, ...;

@end
