//
//  NSString+NinchatTests.m
//  NinchatSDKTests
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+Ninchat.h"

@interface NSStringNinchatTests : XCTestCase

@end

@implementation NSStringNinchatTests

-(void) testContainsTags {
    NSString* s1 = @"Foo. No tags here.";
    XCTAssert(s1.containsTags == NO);

    NSString* s2 = @"This is a string containing a <random> opening tag.";
    XCTAssert(s2.containsTags == YES);

    NSString* s3 = @"<closeTag/> <-- this is it";
    XCTAssert(s3.containsTags == YES);

    NSString* s4 = @"abc <tag> ölöl </tag>";
    XCTAssert(s4.containsTags == YES);

    NSString* s5 = @"What about mere end tag? </ENDTAG>.";
    XCTAssert(s5.containsTags == YES);

    NSString* s6 = @"Well, this is <not > a valid tag.";
    XCTAssert(s6.containsTags == NO);
}

@end
