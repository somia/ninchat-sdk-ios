//
//  NINSessionCredentials.m
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 27.1.2020.
//  Copyright © 2020 Somia Reality Oy. All rights reserved.
//

#import "NINSessionCredentials.h"

@implementation NINSessionCredentials

- (id)init:(NINLowLevelClientProps *)params {
    self = [super init];
    if (self) {
        NSError *error;
        
        NSString* userID = [params getString:@"user_id" error:&error];
        if (error == nil && userID != nil)
            self.userID = userID;
        
        NSString *userAuth = [params getString:@"user_auth" error:&error];
        if (error == nil && userAuth != nil)
            self.userAuth = userAuth;
        
        NSString *sessionID = [params getString:@"session_id" error:&error];
        self.sessionID = sessionID;
    }
    
    return self;
}

-(id _Nonnull)init:(NSString* _Nonnull)userID userAuth:(NSString* _Nonnull)userAuth sessionID:(NSString* _Nullable)sessionID {
    self = [super init];
    if (self) {
        self.userID = userID;
        self.userAuth = userAuth;
        self.sessionID = sessionID;
    }
    
    return self;
}


@end
