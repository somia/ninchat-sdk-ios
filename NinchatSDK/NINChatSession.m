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

@interface NINChatSession ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

@end

@implementation NINChatSession

#pragma mark - Public API

-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController {
    NSAssert([NSThread isMainThread], @"Must be called in main thread");

    if (!self.started) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"NINChat API has not been started; call -startWithCallback first"
                                     userInfo:nil];
    }

    NSBundle* bundle = findResourceBundle(self.class, @"Chat", @"storyboard");
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];

    // Assert that the initial view controller from the Storyboard is a navigation controller
    UINavigationController* navigationController = (UINavigationController*)vc;
    NSAssert([navigationController isKindOfClass:[UINavigationController class]], @"Storyboard initial view controller is not UINavigationController");

    // Find our own initial view controller
    NINInitialViewController* initialViewController = (NINInitialViewController*)navigationController.topViewController;
    NSAssert([initialViewController isKindOfClass:[NINInitialViewController class]], @"Storyboard navigation controller's top view controller is not NINInitialViewController");
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

    // Fetch the site configuration
    fetchSiteConfig(self.sessionManager.configurationKey, ^(NSDictionary* config, NSError* error) {
        NSAssert([NSThread isMainThread], @"Must be called on the main thread");

        if (error != nil) {
            callbackBlock(error);
            return;
        }

        weakSelf.sessionManager.siteConfiguration = config;
        
        // Open the chat session
        error = [weakSelf.sessionManager openSession:^(NSError *error) {
            NSAssert([NSThread isMainThread], @"Must be called on the main thread");

            if (error != nil) {
                callbackBlock(error);
                return;
            }

            // Find our realm's queues
            [weakSelf.sessionManager listQueuesWithCompletion:^(NSError* error) {
                NSAssert([NSThread isMainThread], @"Must be called on the main thread");

                if (error == nil) {
                    weakSelf.started = YES;
                }
                callbackBlock(error);
            }];
        }];

        if (error != nil) {
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
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

// Prevent calling the default initializer
-(id) init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class NINChat"
                                 userInfo:nil];
    return nil;
}

@end