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
#import "NINChatViewController.h"
#import "NINQueue.h"
#import "NINQueueViewController.h"

// Server addresses
static NSString* const kTestServerAddress = @"api.luupi.net";
static NSString* const kProductionServerAddress = @"api.ninchat.com";

// Image asset keys
NINImageAssetKey NINImageAssetKeyIconLoader = @"NINImageAssetKeyQueueViewProgressIndicator";
NINImageAssetKey NINImageAssetKeyChatWritingIndicator = @"NINImageAssetKeyChatWritingIndicator";
NINImageAssetKey NINImageAssetKeyChatBackground = @"NINImageAssetKeyChatBackground";
NINImageAssetKey NINImageAssetKeyChatCloseButton = @"NINImageAssetKeyChatCloseButton";
NINImageAssetKey NINImageAssetKeyIconChatCloseButton = @"NINImageAssetKeyIconChatCloseButton";
NINImageAssetKey NINImageAssetKeyChatBubbleLeft = @"NINImageAssetKeyChatBubbleLeft";
NINImageAssetKey NINImageAssetKeyChatBubbleLeftRepeated = @"NINImageAssetKeyChatBubbleLeftRepeated";
NINImageAssetKey NINImageAssetKeyChatBubbleRight = @"NINImageAssetKeyChatBubbleRight";
NINImageAssetKey NINImageAssetKeyChatBubbleRightRepeated = @"NINImageAssetKeyChatBubbleRightRepeated";
NINImageAssetKey NINImageAssetKeyIconRatingPositive = @"NINImageAssetKeyIconRatingPositive";
NINImageAssetKey NINImageAssetKeyIconRatingNeutral = @"NINImageAssetKeyIconRatingNeutral";
NINImageAssetKey NINImageAssetKeyIconRatingNegative = @"NINImageAssetKeyIconRatingNegative";
NINImageAssetKey NINImageAssetKeyChatAvatarRight = @"NINImageAssetKeyChatAvatarRight";
NINImageAssetKey NINImageAssetKeyChatAvatarLeft = @"NINImageAssetKeyChatAvatarLeft";
NINImageAssetKey NINImageAssetKeyChatPlayVideo = @"NINImageAssetKeyChatPlayVideo";
NINImageAssetKey NINImageAssetKeyIconTextareaCamera = @"NINImageAssetKeyIconTextareaCamera";
NINImageAssetKey NINImageAssetKeyIconTextareaAttachment = @"NINImageAssetKeyIconTextareaAttachment";
NINImageAssetKey NINImageAssetKeyTextareaSubmitButton = @"NINImageAssetKeyTextareaSubmitButton";
NINImageAssetKey NINImageAssetKeyIconTextareaSubmitButtonIcon = @"NINImageAssetKeyIconTextareaSubmitButtonIcon";
NINImageAssetKey NINImageAssetKeyIconVideoToggleFull = @"NINImageAssetKeyIconVideoToggleFull";
NINImageAssetKey NINImageAssetKeyIconVideoToggleNormal = @"NINImageAssetKeyIconVideoToggleNormal";
NINImageAssetKey NINImageAssetKeyIconVideoSoundOn = @"NINImageAssetKeyIconVideoSoundOn";
NINImageAssetKey NINImageAssetKeyIconVideoSoundOff = @"NINImageAssetKeyIconVideoSoundOff";
NINImageAssetKey NINImageAssetKeyIconVideoMicrophoneOn = @"NINImageAssetKeyIconVideoMicrophoneOn";
NINImageAssetKey NINImageAssetKeyIconVideoMicrophoneOff = @"NINImageAssetKeyIconVideoMicrophoneOff";
NINImageAssetKey NINImageAssetKeyIconVideoCameraOn = @"NINImageAssetKeyIconVideoCameraOn";
NINImageAssetKey NINImageAssetKeyIconVideoCameraOff = @"NINImageAssetKeyIconVideoCameraOff";
NINImageAssetKey NINImageAssetKeyIconVideoHangup = @"NINImageAssetKeyIconVideoHangup";
NINImageAssetKey NINImageAssetKeyPrimaryButton = @"NINImageAssetKeyPrimaryButton";
NINImageAssetKey NINImageAssetKeySecondaryButton = @"NINImageAssetKeySecondaryButton";
NINImageAssetKey NINImageAssetKeyIconDownload = @"NINImageAssetKeyIconDownload";

// Color asset keys
NINColorAssetKey NINColorAssetKeyButtonPrimaryText = @"NINColorAssetKeyButtonPrimaryText";
NINColorAssetKey NINColorAssetKeyButtonSecondaryText = @"NINColorAssetKeyButtonSecondaryText";
NINColorAssetKey NINColorAssetKeyInfoText = @"NINColorAssetKeyInfoText";
NINColorAssetKey NINColorAssetKeyChatName = @"NINColorAssetKeyChatName";
NINColorAssetKey NINColorAssetKeyChatTimestamp = @"NINColorAssetKeyChatTimestamp";
NINColorAssetKey NINColorAssetKeyChatBubbleLeftText = @"NINColorAssetKeyChatBubbleLeftText";
NINColorAssetKey NINColorAssetKeyChatBubbleRightText = @"NINColorAssetKeyChatBubbleRightText";
NINColorAssetKey NINColorAssetKeyTextareaText = @"NINColorAssetKeyTextareaText";
NINColorAssetKey NINColorAssetKeyTextareaSubmitText = @"NINColorAssetKeyTextareaSubmitText";
NINColorAssetKey NINColorAssetKeyChatBubbleLeftLink = @"NINColorAssetKeyChatBubbleLeftLink";
NINColorAssetKey NINColorAssetKeyChatBubbleRightLink = @"NINColorAssetKeyChatBubbleRightLink";
NINColorAssetKey NINColorAssetKeyModalText = @"NINColorAssetKeyModalText";
NINColorAssetKey NINColorAssetKeyModalBackground = @"NINColorAssetKeyModalBackground";
NINColorAssetKey NINColorAssetBackgroundTop = @"NINColorAssetBackgroundTop";
NINColorAssetKey NINColorAssetTextTop = @"NINColorAssetTextTop";
NINColorAssetKey NINColorAssetLink = @"NINColorAssetLink";
NINColorAssetKey NINColorAssetBackgroundBottom = @"NINColorAssetBackgroundBottom";
NINColorAssetKey NINColorAssetTextBottom = @"NINColorAssetTextBottom";
NINColorAssetKey NINColorAssetRatingPositiveText = @"NINColorAssetRatingPositiveText";
NINColorAssetKey NINColorAssetRatingNeutralText = @"NINColorAssetRatingNeutralText";
NINColorAssetKey NINColorAssetRatingNegativeText = @"NINColorAssetRatingNegativeText";

@interface NINChatSession ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Configuration key; used to retrieve service configuration (site config) */
@property (nonatomic, strong) NSString* configKey;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

/** ID of the queue to join automatically. Nil to not join automatically to a queue. */
@property (nonatomic, strong) NSString* queueID;

/** Environments to use. */
@property (nonatomic, strong) NSArray<NSString*>* environments;

/** Determines what would be the initial view controller based on the given state: (New Session or Resume Session).*/
@property (nonatomic, assign) BOOL resumeSession;

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

-(void) setAppDetails:(NSString *)appDetails {
    self.sessionManager.appDetails = appDetails;
}

-(NSString*) appDetails {
    return self.sessionManager.appDetails;
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
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"NINChat API has not been started; call -startWithCallback first" userInfo:nil];
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

        // Queue not found!
        [self sdklog:@"Queue with id '%@' not found!", self.queueID];
        return nil;
    }

    UIViewController *viewController;
    if (self.resumeSession) {
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"NINChatViewController"];
        [(NINChatViewController *)viewController setSessionManager:self.sessionManager];
    } else {
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"NINInitialViewController"];
        [(NINInitialViewController *)viewController setSessionManager:self.sessionManager];
    }

    if (withNavigationController) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        /// `https://github.com/somia/ninchat-sdk-ios/issues/62`
        if (@available(iOS 13.0, *))
            [navigationController setOverrideUserInterfaceStyle:UIUserInterfaceStyleLight];
        return navigationController;
    }
    return viewController;
}

/**
 * 1. Check given credentials. If all are set, continues to the previous session.
 * 2. If not, `-startWithCallback:` should be called by the caller to create a new chat session.
 */
-(void) startWithCredentials:(nonnull NINSessionCredentials*)credentials andCallback:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;
    [self sdklog:@"Trying to continue given chat session"];
    
    if (self.sessionManager.siteConfiguration == nil) {
        /// The configuration is not available. First, get the configuration.
        [self fetchSiteConfigurations:^(NSError * _Nullable error) {
            if (error != nil) {
                callbackBlock(nil, error); return;
            }
            
            // Continue the chat session
            [weakSelf continueSessionWithCredentials:credentials andCallbackBlock:callbackBlock];
        }];
    } else {
        /// The configuration are available, just open the session.
        [self continueSessionWithCredentials:credentials andCallbackBlock:callbackBlock];
    }
}

/**
 * Performs these steps:
 * 1. Using that configuration, starts a new chat session
 * 2. Retrieves the queues available for this realm (realm id from site configuration)
 */
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;
    [self sdklog:@"Starting a new chat session"];

    if (self.sessionManager.siteConfiguration == nil) {
        /// The configuration is not available. First, get the configuration.
        [self fetchSiteConfigurations:^(NSError * _Nullable error) {
            if (error != nil) {
                callbackBlock(nil, error); return;
            }
            
            // Open the chat session
            [weakSelf openSession:callbackBlock];
        }];
    } else {
        /// The configuration are availabe, just open the session.
        [self openSession:callbackBlock];
    }
    self.resumeSession = NO;
}

/** Fetching site configurations usable by both approaches to opening sessions */
-(void) fetchSiteConfigurations:(nonnull void (^)(NSError* _Nullable))callbackBlock {
    __weak typeof(self) weakSelf = self;
    
    if (self.sessionManager.serverAddress == nil) {
        // Use a default value for server address
#ifdef NIN_USE_TEST_SERVER
    self.sessionManager.serverAddress = kTestServerAddress;
#else
    self.sessionManager.serverAddress = kProductionServerAddress;
#endif
    }
    
    /// Fetch the site configuration
    fetchSiteConfig(weakSelf.sessionManager.serverAddress, weakSelf.configKey, ^(NSDictionary* config, NSError* error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
        NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

        if (error != nil) {
            callbackBlock(error); return;
        }

        NSLog(@"Got site config: %@", config);
        weakSelf.sessionManager.siteConfiguration = [NINSiteConfiguration siteConfigurationWith:config];
        weakSelf.sessionManager.siteConfiguration.environments = weakSelf.environments;
        callbackBlock(nil);
    });
}

/** Opening a new chat session with no credentials passed by the host application. */
-(void) openSession:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;
    
    NSError* openSessionError = [self.sessionManager openSession:^(NINSessionCredentials *credentials, BOOL canContinueSession, NSError *error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
        NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

        if (error != nil) {
            callbackBlock(credentials, error); return;
        }
        [weakSelf findRealmQueues:credentials andCallbackBlock:callbackBlock];
    }];

    /// Error in opening the session
    /// TODO: Manage different scenarios
    if (openSessionError) {
        callbackBlock(nil, openSessionError);
    }
}

/** Trying to continue connecting to the provided session's credentials. */
-(void) continueSessionWithCredentials:(nonnull NINSessionCredentials*)credentials andCallbackBlock:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;
    NSError* continueSessionError = [self.sessionManager continueSessionWithCredentials:credentials andCallbackBlock:^(NINSessionCredentials* newCredentials, BOOL canContinueSession, NSError* error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
        NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

        if (error != nil || [error.userInfo[@"message"] isEqualToString:@"user_not_found"] || !canContinueSession) {
            if ([weakSelf.delegate respondsToSelector:@selector(ninchatDidFailToResumeSession:)] && [weakSelf.delegate ninchatDidFailToResumeSession:weakSelf]) {}
                [weakSelf startWithCallback:callbackBlock];
            return;
        }
        weakSelf.started = YES;
        weakSelf.resumeSession = canContinueSession;
        callbackBlock(credentials, error);
    }];

    /// Error in opening the session
    /// TODO: Manage different scenarios
    if (continueSessionError) {
        callbackBlock(nil, continueSessionError);
    }
}

- (void) findRealmQueues:(NINSessionCredentials*)credentials andCallbackBlock:(startCallbackBlock)callbackBlock {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

    /// Find our realm's queues
    NSArray<NSString*>* queueIds = [self.sessionManager.siteConfiguration valueForKey:@"audienceQueues"];
    if (queueIds != nil && self.queueID != nil) {
        /// If the queueID we've been initialized with isnt in the config's set of
        /// audienceQueues, add it's ID to the list and we'll see if it exists
        [self sdklog:@"Adding my queueID %@", self.queueID];
        queueIds = [queueIds arrayByAddingObject:self.queueID];
    }

    __weak typeof(self) weakSelf = self;
    [self.sessionManager listQueuesWithIds:queueIds completion:^(NSError* error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

        if (error == nil) {
            weakSelf.started = YES;
        }
        callbackBlock(credentials, error);
    }];
}

-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID {
    return [self initWithConfigKey:configKey queueID:queueID environments:nil];
}

-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID environments:(NSArray<NSString*>* _Nullable)environments{
    self = [super init];
    
    if (self != nil) {
        self.sessionManager = [NINSessionManager new];
        self.sessionManager.ninchatSession = self;
        self.configKey = configKey;
        self.queueID = queueID;
        self.environments = environments;
        self.started = NO;
    }
    
    return self;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

/** Prevent calling the default initializer */
-(id) init {
    self = [super init];

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@", NSStringFromClass(self.class)]
                                 userInfo:nil];
}

@end
