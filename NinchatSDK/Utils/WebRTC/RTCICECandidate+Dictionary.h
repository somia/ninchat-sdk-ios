//
//  RTCICECandidate+Dictionary.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCICECandidate.h"

/**
 * Methods for converting RTCICECandidate to / from dictionary representation.
 *
 * The dictionary format is compatible with JSON encoding of the object.
 */
@interface RTCICECandidate (Dictionary)

-(NSDictionary*) dictionary;

@end
