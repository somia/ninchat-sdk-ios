//
//  NINSessionCredentials.m
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 27.1.2020.
//  Copyright © 2020 Somia Reality Oy. All rights reserved.
//

#import "NINSessionCredentials.h"

@implementation NINSessionCredentials 

-(id) init:(NINLowLevelClientProps *)params {
    self = [super init];
    if (self) {
        NSError *error;
        
        NSString* userID = [params getString:@"user_id" error:&error];
        if (error == nil && userID != nil)
            self.userID = userID;
        
        NSString *userAuth = [params getString:@"user_auth" error:&error];
        if (error == nil && userAuth != nil)
            self.userAuth = userAuth;
    }
    
    return self;
}

-(id _Nonnull) init:(NSString* _Nonnull)userID userAuth:(NSString* _Nonnull)userAuth {
    self = [super init];
    if (self) {
        self.userID = userID;
        self.userAuth = userAuth;
    }
    
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.userID = [aDecoder decodeObjectForKey:@"user_id"];
        self.userAuth = [aDecoder decodeObjectForKey:@"user_auth"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.userID forKey:@"user_id"];
    [coder encodeObject:self.userAuth forKey:@"user_auth"];
}

@end
