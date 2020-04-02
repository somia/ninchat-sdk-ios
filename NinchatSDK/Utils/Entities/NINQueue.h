//
//  NINQueue.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

//#import <Foundation/Foundation.h>
@import Foundation;

/** Describes a single queue. */
@interface NINQueue : NSObject

@property (nonatomic, strong, readonly) NSString* queueID;
@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, assign, readonly) BOOL isClosed;

+(NINQueue*) queueWithId:(NSString*)queueId andName:(NSString*)name isClosed:(BOOL)isClosed;

@end
