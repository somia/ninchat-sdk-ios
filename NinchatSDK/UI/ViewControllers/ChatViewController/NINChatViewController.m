//
//  ChatViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatViewController.h"
#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINChannelMessage.h"
#import "NINWebRTCClient.h"
#import "NINVideoCallViewController.h"
#import "NINChatView.h"

static NSString* const kSegueIdChatToRating = @"ninchatsdk.segue.ChatToRatings";
static NSString* const kSegueIdChatToVideoCall = @"ninchatsdk.segue.ChatToVideoCall";

@interface NINChatViewController () <NINChatViewDataSource>

// The chat messages view
@property (nonatomic, strong) IBOutlet NINChatView* chatView;

// Reference to the notifications observer that listens to new message -notifications.
@property (nonatomic, strong) id<NSObject> messagesObserver;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

@end

@implementation NINChatViewController

#pragma mark - Private methods

-(void) sendButtonPressed:(id)sender {
    NSString* text = @"TODO";

    [self.sessionManager sendTextMessage:text completion:^(NSError* _Nonnull error) {
        if (error != nil) {
            //TODO show error toast? check with UX people.
            NSLog(@"TODO: message failed to send - show error message");
        }
    }];
}

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdChatToVideoCall]) {
        NINVideoCallViewController* vc = segue.destinationViewController;
        NSDictionary* params = (NSDictionary*)sender;
        vc.webrtcClient = params[@"client"];
        vc.offerSDP = params[@"sdp"];
    }
}

#pragma mark - From NINChatViewDataSource

- (NSString *)chatView:(NINChatView *)chatView avatarURLAtIndex:(NSInteger)index {
    //TODO implement me
    return nil;
}

- (BOOL)chatView:(NINChatView *)chatView isMessageFromMeAtIndex:(NSInteger)index {
    NINChannelMessage* msg = self.sessionManager.channelMessages[index];
    return msg.mine;
}

- (NSString *)chatView:(NINChatView *)chatView messageTextAtIndex:(NSInteger)index {
    NINChannelMessage* msg = self.sessionManager.channelMessages[index];
    return msg.textContent;
}

- (NSInteger)numberOfMessagesForChatView:(NINChatView *)chatView {
    return self.sessionManager.channelMessages.count;
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak typeof(self) weakSelf = self;

    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        [self.chatView newMessageWasAdded];

        return NO;
    });

    // Start listening to WebRTC signaling messages from the chat session manager
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCOffer]) {
            NSLog(@"Got WebRTC offer - initializing webrtc for video call (answer)");

            NSData* payloadData = note.userInfo[@"payload"];
            NSError* jsonError = nil;
            NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:payloadData options:kNilOptions error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"Failed to parse JSON: %@", jsonError);
                return NO;
            }

            NSLog(@"Parsed payloadDict: %@", payloadDict);
            NSLog(@"Offer SDP: %@", payloadDict[@"sdp"]);

            // Fetch our STUN / TURN server information
            [weakSelf.sessionManager beginICEWithCompletionCallback:^(NSError* error, NSArray<NINWebRTCServerInfo*>* stunServers, NSArray<NINWebRTCServerInfo*>* turnServers) {

                // Create a WebRTC client for the video call
                NINWebRTCClient* client = [NINWebRTCClient clientWithSessionManager:weakSelf.sessionManager operatingMode:NINWebRTCClientOperatingModeCallee stunServers:stunServers turnServers:turnServers];

                // Open the video call view
                NSDictionary* params = @{@"client": client, @"sdp": payloadDict[@"sdp"]};
                [weakSelf performSegueWithIdentifier:kSegueIdChatToVideoCall sender:params];
            }];
        }

        return NO;
    });
    
    // Listen to channel closed -events
    fetchNotification(kNINChannelClosedNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Channel closed - showing rating view.");

        // First pop the chat view
        [weakSelf.navigationController popToViewController:self animated:YES];

        // Show the rating view
        [weakSelf performSegueWithIdentifier:kSegueIdChatToRating sender:nil];

        return YES;
    });
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = self.title;

    self.chatView.dataSource = self;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
