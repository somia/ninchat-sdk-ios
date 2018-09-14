//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatSession.h"
#import "NINInitialViewController.h"
#import "NINUtils.h"
#import "NINSessionManager.h"
#import "NINChatSession+Internal.h"

@interface NINChatSession ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

@end

@implementation NINChatSession

#pragma mark - Public API

-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController {
    NSCAssert([NSThread isMainThread], @"Must be called in main thread");

    if (!self.started) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"NINChat API has not been started; call -startWithCallback first"
                                     userInfo:nil];
    }

    NSBundle* bundle = findResourceBundle();
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];

    // Assert that the initial view controller from the Storyboard is a navigation controller
    UINavigationController* navigationController = (UINavigationController*)vc;
    NSCAssert([navigationController isKindOfClass:[UINavigationController class]], @"Storyboard initial view controller is not UINavigationController");

    // Find our own initial view controller
    NINInitialViewController* initialViewController = (NINInitialViewController*)navigationController.topViewController;
    NSCAssert([initialViewController isKindOfClass:[NINInitialViewController class]], @"Storyboard navigation controller's top view controller is not NINInitialViewController");
    initialViewController.sessionManager = self.sessionManager;
    
    if (withNavigationController) {
        return navigationController;
    } else {
        return initialViewController;
    }
}

// Performs these steps:
// 1. Fetches the site configuration over a REST call
// 2. Using that configuration, starts a new chat session
// 3. Retrieves the queues available for this realm (realm id from site configuration)
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;

    [self sdklog:@"Starting a chat session"];

    // Fetch the site configuration
    fetchSiteConfig(weakSelf.sessionManager.configurationKey, ^(NSDictionary* config, NSError* error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
        NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

        if (error != nil) {
            callbackBlock(error);
            return;
        }

        weakSelf.sessionManager.siteConfiguration = config;

        // Open the chat session
        NSError* openSessionError = [weakSelf.sessionManager openSession:^(NSError *error) {
            NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
            NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

            if (error != nil) {
                callbackBlock(error);
                return;
            }

            // Find our realm's queues
            [weakSelf.sessionManager listQueuesWithCompletion:^(NSError* error) {
                NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

                if (error == nil) {
                    weakSelf.started = YES;
                }
                callbackBlock(error);
            }];
        }];

        if (openSessionError != nil) {
            callbackBlock(error);
        }
    });
}

-(id) initWithConfigurationKey:(NSString*)configKey siteSecret:(NSString* _Nullable)siteSecret {
    self = [super init];

    if (self != nil) {
        self.sessionManager = [NINSessionManager new];
        self.sessionManager.ninchatSession = self;
        self.sessionManager.configurationKey = configKey;
        self.sessionManager.siteSecret = siteSecret;
        self.started = NO;
    }

    return self;
}

-(void) dealloc {
    //TODO remove
    self.sessionManager = nil;

    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

// Prevent calling the default initializer
-(id) init {
    self = [super init];

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@", NSStringFromClass(self.class)]
                                 userInfo:nil];
    return nil;
}

@end
