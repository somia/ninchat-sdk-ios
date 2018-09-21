//
//  NINClientPropsParser.h
//  AppRTC
//
//  Created by Matti Dahlbom on 12/07/2018.
//

#import <Foundation/Foundation.h>

// Import the ported Go SDK framework
#if __has_feature(modules)
@import Client;
#else
#import <Client/Client.h>
#endif

/** Parses a ClientProps object via its -accept method. */
@interface NINClientPropsParser : NSObject <ClientPropVisitor>

/** Parsed properties. The value types will be NSString, NSNumber, ClientProps, ClientObjects or ClientStrings. */
@property (nonatomic, strong) NSDictionary<NSString*, id>* properties;

@end
