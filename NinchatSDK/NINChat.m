//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChat.h"
#import "NINMessagesViewController.h"
//#import "Utils.h"
#import "SessionManager.h"

@interface NINChat ()

/** Session manager instance. */
@property (nonatomic, strong) SessionManager* sessionManager;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

@end

@implementation NINChat

#pragma mark - Private API


#pragma mark - Public API

-(nonnull UIViewController*) viewController {
    NSAssert([NSThread isMainThread], @"Must be called in main thread");

    if (!self.started) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"NINChat API has not been started; call -startWithCallback first"
                                     userInfo:nil];
    }

    NSLog(@"Loading initial view controller..");

    // Locate our framework bundle by showing it a class in this framework
    NSBundle* classBundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"frameworkBundle: %@", classBundle);

    UIStoryboard* storyboard = nil;

    // See if this top level bundle contains our storyboard
    if ([classBundle pathForResource:@"Chat" ofType:@"storyboard"] != nil) {
        // This path is taken when using the SDK from a prebuilt .framework.
        NSLog(@"storyboard found in class bundle");
        storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:classBundle];
    } else {
        // This path is taken when using the SDK via Cocoapods module.
        // Locate our UI resource bundle. This is specified in the podspec file.
        NSLog(@"storyboard not found in class bundle");
        NSURL* bundleURL = [classBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
        NSBundle* bundle = [NSBundle bundleWithURL:bundleURL];
        storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];
    }

    NSLog(@"storyboard: %@", storyboard);

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];
    NINMessagesViewController* initialViewController = nil;

    // Find our own initial view controller
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)vc;
        initialViewController = (NINMessagesViewController*)navigationController.topViewController;
    } else if ([vc isKindOfClass:[NINMessagesViewController class]]) {
        initialViewController = (NINMessagesViewController*)vc;
    } else {
        NSLog(@"Invalid initial view controller from Storyboard: %@", vc.class);
        return nil;
    }

    initialViewController.sessionManager = self.sessionManager;
    
    NSLog(@"Instantiated initial view controller: %@", vc);

    return vc;
}

-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock {
    NSError* error = [self.sessionManager openSession:^(NSError *error) {
        NSAssert([NSThread isMainThread], @"Must be called in main thread");
        if (error == nil) {
            self.started = YES;
        }
        callbackBlock(error);
    }];

    if (error != nil) {
        callbackBlock(error);
    }
}

-(id) initWithRealmId:(NSString*)realmId {
    self = [super init];

    if (self != nil) {
        self.sessionManager = [SessionManager new];
        self.sessionManager.realmId = realmId;
        self.started = NO;
    }

    return self;
}

// Prevent calling the default initializer
-(id) init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class NINChat"
                                 userInfo:nil];
    return nil;
}

@end
