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
#import "NINTouchView.h"

static NSString* const kSegueIdChatToRating = @"ninchatsdk.segue.ChatToRatings";
static NSString* const kSegueIdChatToVideoCall = @"ninchatsdk.segue.ChatToVideoCall";

@interface NINChatViewController () <NINChatViewDataSource>

// The chat messages view
@property (nonatomic, strong) IBOutlet NINChatView* chatView;

// The chat view height constraint
//@property (nonatomic, strong) IBOutlet NSLayoutConstraint* chatViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint* chatViewHeightConstraint;

//
//// The video view height constraint
//@property (nonatomic, strong) IBOutlet NSLayoutConstraint* videoViewHeightConstraint;

// This view is used to detect a tap outside the keyboard to close it
@property (nonatomic, strong) NINTouchView* tapRecognizerView;

// The text input box
@property (nonatomic, strong) IBOutlet UITextField* textInputField;

// Reference to the notifications observer that listens to new message -notifications.
@property (nonatomic, strong) id<NSObject> messagesObserver;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

@end

@implementation NINChatViewController

#pragma mark - Private methods

-(void) listenToWebRTCSignaling {
    if (self.signalingObserver != nil) {
        // Already listening..
        return;
    }

    __weak typeof(self) weakSelf = self;
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCCall]) {
            NSLog(@"Got WebRTC call - replying with pick-up");

            //TODO show UI dialog here; ask the user whether to pick up. if not, must set answer: false below

            [weakSelf.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCPickup payloadDict:@{@"answer": @(YES)} completion:^(NSError* error) {
                if (error != nil) {
                    NSLog(@"Failed to send pick-up message: %@", error);
                    //TODO handle
                }
            }];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCOffer]) {
            NSLog(@"Got WebRTC offer - initializing webrtc for video call (answer)");

            NSDictionary* payload = note.userInfo[@"payload"];
            NSLog(@"Offer payload: %@", payload);

            // Fetch our STUN / TURN server information
            [weakSelf.sessionManager beginICEWithCompletionCallback:^(NSError* error, NSArray<NINWebRTCServerInfo*>* stunServers, NSArray<NINWebRTCServerInfo*>* turnServers) {

                // Create a WebRTC client for the video call
                NINWebRTCClient* client = [NINWebRTCClient clientWithSessionManager:weakSelf.sessionManager operatingMode:NINWebRTCClientOperatingModeCallee stunServers:stunServers turnServers:turnServers];

                // Open the video call view
                NSDictionary* params = @{@"client": client, @"sdp": payload[@"sdp"]};
                [weakSelf performSegueWithIdentifier:kSegueIdChatToVideoCall sender:params];
            }];
        }

        return NO;
    });
}

-(void) adjustConstraints:(BOOL)portrait {
    if (portrait) {
        // Portrait; disable chat view height constraint
        if (self.chatViewHeightConstraint != nil) {
            self.chatViewHeightConstraint.active = NO;
            self.chatViewHeightConstraint = nil;
        }
    } else {
        // Landscape; set the chat height constraint to 0. We have to do this
        // manually here b/c the 'embeddable' view trick cannot catch this change.
        if (self.chatViewHeightConstraint == nil) {
            self.chatViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.chatView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
            self.chatViewHeightConstraint.priority = 999;
            self.chatViewHeightConstraint.active = YES;
        }
    }
}

#pragma mark - IBAction handlers

-(IBAction) sendButtonPressed:(id)sender {
    NSString* text = [self.textInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.textInputField.text = nil;
    [self.textInputField resignFirstResponder];

    if ([text length] > 0) {
        [self.sessionManager sendTextMessage:text completion:^(NSError* _Nonnull error) {
            if (error != nil) {
                //TODO show error toast? check with UX people.
                NSLog(@"TODO: message failed to send - show error message");
            }
        }];
    }
}

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdChatToVideoCall]) {
        NINVideoCallViewController* vc = segue.destinationViewController;
        NSDictionary* params = (NSDictionary*)sender;
        vc.sessionManager = self.sessionManager;
        vc.webrtcClient = params[@"client"];
        vc.offerSDP = params[@"sdp"];
    }
}

#pragma mark - From UIContentController

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self adjustConstraints:(size.height > size.width)];
}

#pragma mark - From NINChatViewDataSource

- (NSString *)chatView:(NINChatView *)chatView avatarURLAtIndex:(NSInteger)index {
    NINChannelMessage* msg = self.sessionManager.channelMessages[index];
    return msg.avatarURL;
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

#pragma mark - From NINBaseViewController

-(void) keyboardWillShow:(NSNotification *)notification {
    [super keyboardWillShow:notification];

    if (self.tapRecognizerView == nil) {
        __weak typeof(self) weakSelf = self;
        self.tapRecognizerView = [[NINTouchView alloc] initWithFrame:self.chatView.bounds];
        self.tapRecognizerView.tag = 666;

        self.tapRecognizerView.touchCallback = ^{
            // Get rid of the keyboard
            [weakSelf.textInputField resignFirstResponder];
            NSLog(@"touched tapRecognizerView");
        };

        [self.chatView addSubview:self.tapRecognizerView];
        NSLog(@"added tapRecognizerView");
    }
}

-(void) keyboardWillHide:(NSNotification *)notification {
    [super keyboardWillHide:notification];

    [self.tapRecognizerView removeFromSuperview];
    self.tapRecognizerView = nil;
    NSLog(@"removed tapRecognizerView");
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self adjustConstraints:(self.view.frame.size.height > self.view.frame.size.width)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    __weak typeof(self) weakSelf = self;

    // Start listening to new messages
    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        [self.chatView newMessageWasAdded];

        return NO;
    });

    // Start listening to WebRTC signaling messages from the chat session manager
    [self listenToWebRTCSignaling];
    
    // Listen to channel closed -events
    fetchNotification(kNINChannelClosedNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Channel closed - showing rating view.");

        // Show the rating view
        [weakSelf performSegueWithIdentifier:kSegueIdChatToRating sender:nil];

        return YES;
    });
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
