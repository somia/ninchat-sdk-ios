//
//  NINClientPropsParser.h
//  AppRTC
//
//  Created by Matti Dahlbom on 12/07/2018.
//

#import <Foundation/Foundation.h>

// Import the ported Go SDK framework
@import Client;

/** Parses a ClientProps object via its -accept method. */
@interface NINClientPropsParser : NSObject <ClientPropVisitor>

/** Parsed properties. The value types will be NSString, NSNumber, ClientProps or ClientStrings. */
@property (nonatomic, strong) NSDictionary<NSString*, id>* properties;

@end
