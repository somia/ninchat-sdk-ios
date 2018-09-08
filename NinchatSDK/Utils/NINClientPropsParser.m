//
//  NINClientPropsParser.m
//  AppRTC
//
//  Created by Matti Dahlbom on 12/07/2018.
//

#import "NINClientPropsParser.h"

@interface NINClientPropsParser () {
    // Backing mutable dictionary for parsed properties
    NSMutableDictionary* _properties;
}

@end

@implementation NINClientPropsParser

#pragma mark - From ClientPropVisitor

- (BOOL)visitBool:(NSString*)p0 p1:(BOOL)p1 error:(NSError**)error {
    NSLog(@"Parsed BOOL '%@' = %d", p0, p1);
    _properties[p0] = @(p1);
    return YES;
}

- (BOOL)visitNumber:(NSString*)p0 p1:(double)p1 error:(NSError**)error {
    NSLog(@"Parsed Number '%@' = %f", p0, p1);
    _properties[p0] = @(p1);
    return YES;
}

- (BOOL)visitObject:(NSString*)p0 p1:(ClientProps*)p1 error:(NSError**)error {
    NSLog(@"Parsed Object '%@'", p0);
    _properties[p0] = p1;
    return YES;
}

- (BOOL)visitString:(NSString*)p0 p1:(NSString*)p1 error:(NSError**)error {
    NSLog(@"Parsed String '%@' = %@", p0, p1);
    _properties[p0] = p1;
    return YES;
}

- (BOOL)visitStringArray:(NSString*)p0 p1:(ClientStrings*)p1 error:(NSError**)error {
    NSLog(@"Parsed StringArray '%@'", p0);
    _properties[p0] = p1;
    return YES;
}

- (BOOL)visitObjectArray:(NSString *)p0 p1:(ClientObjects *)p1 error:(NSError *__autoreleasing *)error {
    NSLog(@"Parsed ClientObjects '%@'", p0);
    _properties[p0] = p1;
    return YES;
}

#pragma mark - Lifecycle etc.

-(id) init {
    self = [super init];

    if (self != nil) {
        _properties = [NSMutableDictionary dictionaryWithCapacity:10];
    }

    return self;
}

@end