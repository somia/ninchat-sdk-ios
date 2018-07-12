//
//  NINQueue.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Describes a single queue. */
@interface NINQueue : NSObject

@property (nonatomic, strong, readonly) NSString* queueId;
@property (nonatomic, strong, readonly) NSString* name;

+(NINQueue*) queueWithId:(NSString*)queueId andName:(NSString*)name;

@end
