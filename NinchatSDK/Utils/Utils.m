//
//  Utils.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Utils.h"

// Notification strings
NSString* const kNewChannelMessageNotification = @"ninchatsdk.NewChannelMessageNotification";

NSError* newError(NSString* msg) {
    return [NSError errorWithDomain:@"NinchatSDK" code:1 userInfo:@{@"message": msg}];
}

void runOnMainThread(emptyBlock block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

void postNotification(NSString* notificationName, NSDictionary* userInfo) {
    runOnMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:userInfo];
    });
}

id fetchNotification(NSString* notificationName, notificationBlock _Nonnull block) {
    id observer = nil;

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (block(note)) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
    }];

    return observer;
}

NSBundle* findResourceBundle(Class class, NSString* resourceName, NSString* resourceType) {
    NSBundle* classBundle = [NSBundle bundleForClass:class];

    // See if this top level bundle contains our resource
    if ([classBundle pathForResource:resourceName ofType:resourceType] != nil) {
        // This path is taken when using the SDK from a prebuilt .framework.
        return classBundle;
    } else {
        // This path is taken when using the SDK via Cocoapods module.
        // Locate our UI resource bundle. This is specified in the podspec file.
        NSURL* bundleURL = [classBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
        return [NSBundle bundleWithURL:bundleURL];
    }
}


