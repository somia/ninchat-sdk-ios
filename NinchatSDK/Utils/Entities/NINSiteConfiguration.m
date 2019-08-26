//
//  NINSiteConfiguration.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 23/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINSiteConfiguration.h"

@interface NINSiteConfiguration ()

@property (nonatomic, strong) NSDictionary* configDict;

@end

@implementation NINSiteConfiguration

-(id)valueForKey:(NSString*)key {
    NSObject* value = self.configDict[self.configName][key];
    if (value != nil) {
        return value;
    } else {
        return self.configDict[@"default"][key];
    }
}

-(NSArray<NSString*>*)availableConfigurations {
    return [self.configDict allKeys];
}

/** Instantiates with provided siteconfig json. */
+(NINSiteConfiguration*)siteConfigurationWith:(NSDictionary*)dict {
    NINSiteConfiguration* config = [[NINSiteConfiguration alloc] init];
    config.configDict = dict;
    config.configName = @"asdffsd";
    return config;
}

@end
