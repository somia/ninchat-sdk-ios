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
@interface NINSessionCredentials: NSObject <NSCoding>

/* User identification */
@property (nonatomic, strong, nonnull) NSString* userID;

/* User authentication */
@property (nonatomic, strong, nonnull) NSString* userAuth;


/* Initiate the model using `NINLowLevelClientProps` received from server */
-(id _Nonnull)init:(NINLowLevelClientProps* _Nonnull)params;

/* Initiate the model using cached/saved values */
-(id _Nonnull)init:(NSString* _Nonnull)userID userAuth:(NSString* _Nonnull)userAuth;

@end
