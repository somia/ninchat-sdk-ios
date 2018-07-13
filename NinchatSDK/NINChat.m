//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChat.h"
#import "NINInitialViewController.h"
#import "NINUtils.h"
#import "NINSessionManager.h"

@interface NINChat ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

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

    NSBundle* bundle = findResourceBundle(self.class, @"Chat", @"storyboard");
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];
    NINInitialViewController* initialViewController = nil;

    // Find our own initial view controller
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)vc;

        initialViewController = (NINInitialViewController*)navigationController.topViewController;
    } else if ([vc isKindOfClass:[NINInitialViewController class]]) {
        initialViewController = (NINInitialViewController*)vc;
    } else {
        NSLog(@"Invalid initial view controller from Storyboard: %@", vc.class);
        return nil;
    }

    initialViewController.sessionManager = self.sessionManager;
    
    NSLog(@"Instantiated initial view controller: %@", vc);

    return vc;
}

// Performs these steps:
// 1. Fetches the site configuration over a REST call
// 2. Using that configuration, starts a new chat session
// 3. Retrieves the queues available for this realm (realm id from site configuration)
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock {
    // Fetch the site configuration
    fetchSiteConfig(self.sessionManager.configurationKey, ^(NSDictionary* config, NSError* error) {
        NSAssert([NSThread isMainThread], @"Must be called on the main thread");

        if (error != nil) {
            callbackBlock(error);
            return;
        }

        self.sessionManager.siteConfiguration = config;
        
        // Open the chat session
        error = [self.sessionManager openSession:^(NSError *error) {
            NSAssert([NSThread isMainThread], @"Must be called on the main thread");

            if (error != nil) {
                callbackBlock(error);
                return;
            }

            // Find our realm's queues
            [self.sessionManager listQueuesWithCompletion:^(NSError* error) {
                NSAssert([NSThread isMainThread], @"Must be called on the main thread");

                if (error == nil) {
                    self.started = YES;
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
        self.sessionManager.configurationKey = configKey;
        self.sessionManager.siteSecret = siteSecret;
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
