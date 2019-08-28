//
//  NINUIComposeMessage.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 08/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChannelMessage.h"

static NSString* const kUIComposeMessageElementA = @"a";
static NSString* const kUIComposeMessageElementButton = @"button";
static NSString* const kUIComposeMessageElementSelect = @"select";

@class NINChannelUser;

@interface NINUIComposeMessage : NSObject<NINChannelMessage>

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign) BOOL series;

/** Element class. */
@property (nonatomic, strong, readonly) NSString* className;
/** Element type. API specifies "a", "button" and "select", SDK currently only supports "select". */
@property (nonatomic, strong, readonly) NSString* element;
/** Link target for element type "a". */
@property (nonatomic, strong, readonly) NSString* href;
/** Element unique identifier. */
@property (nonatomic, strong, readonly) NSString* uid;
/** Element name. */
@property (nonatomic, strong, readonly) NSString* name;
/** A label or a descriptive text depending on the element. Text prompt on "select". */
@property (nonatomic, strong, readonly) NSString* label;
/** Array of NINUIComposeOption elements for "select" type element. */
@property (nonatomic, strong, readonly) NSArray<NSDictionary*>* options;

/** Instance data as a dictionary, with options property replaced if parameter is non-nil. */
-(NSDictionary*) dictWithOptions:(NSArray<NSDictionary*>*)options;

+(NINUIComposeMessage*) messageWithID:(NSString*)messageID sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine className:(NSString*)className element:(NSString*)element href:(NSString*)href uid:(NSString*)uid name:(NSString*)name label:(NSString*)label options:(NSArray<NSDictionary*>*)options;

@end

