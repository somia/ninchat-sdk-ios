//
//  NSString+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import "NSMutableAttributedString+Ninchat.h"
#import "NSString+Ninchat.h"

@implementation NSString (Ninchat)

-(NSAttributedString*) htmlAttributedStringWithFont:(UIFont*)font {
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:NULL error:NULL];
    [attrString overrideFont:font];

    return attrString;
}

@end
