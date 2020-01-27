//
//  NINSessionCredentials.h
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 27.1.2020.
//  Copyright © 2020 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>
@import NinchatLowLevelClient;

/* Stores Session credentials */
@interface NINSessionCredentials : NSObject

/* User identification */
@property (nonatomic, strong, nonnull) NSString* userID;

/* User authentication */
@property (nonatomic, strong, nonnull) NSString* userAuth;

/* Corresponded session_id (optional) */
@property (nonatomic, strong, nullable) NSString* sessionID;

-(id _Nonnull)init:(NINLowLevelClientProps* _Nonnull)params;

@end
