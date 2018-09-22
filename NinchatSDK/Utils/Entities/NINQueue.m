//
//  NINQueue.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 12/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINQueue.h"

@interface NINQueue ()

// Private writable versions of the properties
@property (nonatomic, strong) NSString* queueID;
@property (nonatomic, strong) NSString* name;

@end

@implementation NINQueue

-(NSString*) description {
    return [NSString stringWithFormat:@"Queue ID: %@, Name: %@", self.queueID, self.name];
}

+(NINQueue*) queueWithId:(NSString*)queueId andName:(NSString*)name {
    NINQueue* queue = [NINQueue new];
    queue.queueID = queueId;
    queue.name = name;

    return queue;
}

@end
