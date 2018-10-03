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
#import "NINQueue.h"
#import "NINQueueViewController.h"

// Image asset keys
NINImageAssetKey NINImageAssetKeyQueueViewProgressIndicator = @"NINImageAssetKeyQueueViewProgressIndicator";
NINImageAssetKey NINImageAssetKeyChatUserTypingIndicator = @"NINImageAssetKeyChatUserTypingIndicator";
NINImageAssetKey NINImageAssetKeyInitialViewJoinQueueButton = @"NINImageAssetKeyJoinQueueButton";
NINImageAssetKey NINImageAssetKeyInitialViewCloseWindowButton = @"NINImageAssetKeyCloseWindowButton";
NINImageAssetKey NINImageAssetKeyChatViewBackgroundTexture = @"NINImageAssetKeyChatBackground";
NINImageAssetKey NINImageAssetKeyCloseChatButton = @"NINImageAssetKeyCloseChatButton";

@interface NINChatSession ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Configuration key; used to retrieve service configuration (site config) */
@property (nonatomic, strong) NSString* configKey;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

/** ID of the queue to join automatically. Nil to not join automatically to a queue. */
@property (nonatomic, strong) NSString* queueID;

@end

@implementation NINChatSession

#pragma mark - Public API

-(void) setServerAddress:(NSString*)serverAddress {
    self.sessionManager.serverAddress = serverAddress;
}

-(NSString*) serverAddress {
    return self.sessionManager.serverAddress;
}

-(void) setSiteSecret:(NSString*)siteSecret {
    self.sessionManager.siteSecret = siteSecret;
}

-(NSString*) siteSecret {
    return self.sessionManager.siteSecret;
}

-(void) setAudienceMetadata:(NINLowLevelClientProps*)audienceMetadata {
    self.sessionManager.audienceMetadata = audienceMetadata;
}

-(NINLowLevelClientProps*) audienceMetadata {
    return self.sessionManager.audienceMetadata;
}

-(NINLowLevelClientSession*) session {
    NSCAssert(self.started, @"API has not been started");

    return self.sessionManager.session;
}

-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController {
    NSCAssert([NSThread isMainThread], @"Must be called in main thread");

    if (!self.started) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"NINChat API has not been started; call -startWithCallback first"
                                     userInfo:nil];
    }

    NSBundle* bundle = findResourceBundle();
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // If a queue ID is specified, look that queue up and join it automatically
    if (self.queueID != nil) {
        // Find the queue object by its ID
        for (NINQueue* queue in self.sessionManager.queues) {
            if ([queue.queueID isEqualToString:self.queueID]) {
                // Load queue view controller directly
                NINQueueViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"NINQueueViewController"];
                NSCAssert([vc isKindOfClass:NINQueueViewController.class], @"Invalid NINQueueViewController");
                vc.sessionManager = self.sessionManager;
                vc.queueToJoin = queue;

                return vc;
            }
        }

        NSCAssert(false, @"Queue not found!");
        [self sdklog:@"Queue with id '%@' not found!", self.queueID];
        return nil;
    }

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
    fetchSiteConfig(weakSelf.sessionManager.serverAddress, weakSelf.configKey, ^(NSDictionary* config, NSError* error) {
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

-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID {
    self = [super init];

    if (self != nil) {
        self.sessionManager = [NINSessionManager new];
        self.sessionManager.ninchatSession = self;
        self.configKey = configKey;
        self.queueID = queueID;
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
