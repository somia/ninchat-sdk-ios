//
//  Utils.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINUtils.h"
#import "NINInitialViewController.h"

// Server host name.
//NSString* const kNinchatServerHostName = @"api.ninchat.com"; // production
NSString* const kNinchatServerHostName = @"api.luupi.net"; // test

// Site config URL pattern. Populate with kServerHostName & configuration key
static NSString* const kSiteConfigUrlPattern = @"https://%@/config/%@";

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
    id __block observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (block(note)) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
    }];

    return observer;
}

NSBundle* findResourceBundle(Class class) {
//    NSBundle* classBundle = [NSBundle bundleForClass:class];
    NSBundle* classBundle = [NSBundle bundleForClass:[NINInitialViewController class]];
    NSCAssert(classBundle != nil, @"Nil classBundle");

    NSURL* bundleURL = [classBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
    if (bundleURL == nil) {
        // This path is taken when using the SDK from a prebuilt .framework.
        return classBundle;
    } else {
        // This path is taken when using the SDK via Cocoapods module.
        // Locate our UI resource bundle. This is specified in the podspec file.
        NSBundle* resourceBundle = [NSBundle bundleWithURL:bundleURL];
        NSCAssert(resourceBundle != nil, @"Nil resourceBundle");

        return resourceBundle;
    }
}

void fetchSiteConfig(NSString* configurationKey, fetchSiteConfigCallbackBlock callbackBlock) {
    NSString* url = [NSString stringWithFormat:kSiteConfigUrlPattern, kNinchatServerHostName, configurationKey];
    NSLog(@"Fetching site config from URL: %@", url);

    void (^callCallback)(NSDictionary* config, NSError* error) = ^(NSDictionary* config, NSError* error) {
        runOnMainThread(^{
            callbackBlock(config, error);
        });
    };

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    [request setHTTPMethod: @"GET"];

    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 10.0;
    sessionConfig.timeoutIntervalForResource = 10.0;

    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse* response, NSError* error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;

        if (error != nil) {
            callCallback(nil, error);
            return;
        }

        if ((httpResponse.statusCode < 200) || (httpResponse.statusCode >= 300)) {
            callCallback(nil, newError([NSString stringWithFormat:@"Got response code: %ld", (long)httpResponse.statusCode]));
            return;
        }

        NSError* parseError = nil;
        NSDictionary* config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError != nil) {
            callCallback(nil, error);
            return;
        }

        NSLog(@"Got site config: %@", config);
        callCallback(config, nil);
    }];
    
    [dataTask resume];
}


