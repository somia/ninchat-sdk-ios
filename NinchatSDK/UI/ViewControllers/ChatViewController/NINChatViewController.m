//
//  ChatViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import MobileCoreServices;

#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AVFoundation/AVFoundation.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>

#import "NINChatViewController.h"
#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINChannelMessage.h"
#import "NINWebRTCClient.h"
#import "NINChatView.h"
#import "NINTouchView.h"
#import "NINVideoCallConsentDialog.h"
#import "NINRatingViewController.h"
#import "NINCloseChatButton.h"

static NSString* const kSegueIdChatToRating = @"ninchatsdk.segue.ChatToRatings";

static const NSTimeInterval kAnimationDuration = 0.3;

// UI (Localizable) strings
static NSString* const kCloseChatText = @"Close chat";

@interface NINChatViewController () <NINChatViewDataSource, NINWebRTCClientDelegate, RTCEAGLVideoViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// Our video views; one for remote (received) and one for local (capturing device camera feed)
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView* remoteVideoView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView* localVideoView;

// Remote video view constraints for adjusting aspect ratio
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* remoteViewHeightConstraint;

// Local video view constraints for adjusting aspect ratio
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* localViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* localViewHeightConstraint;

// The video container view
@property (nonatomic, strong) IBOutlet UIView* videoContainerView;

// Height constraint of the video container view
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* videoContainerViewHeightConstraint;

// Height constraint of the chst view
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* chatViewHeightConstraint;

// Height constraint of the chst input controls view
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* chatInputControlsViewHeightConstraint;

// The chat messages view
@property (nonatomic, strong) IBOutlet NINChatView* chatView;

// The close chat button
@property (nonatomic, strong) IBOutlet NINCloseChatButton* closeChatButton;

// Remote video track
@property (strong, nonatomic) RTCVideoTrack* remoteVideoTrack;

// Local video track
@property (strong, nonatomic) RTCVideoTrack* localVideoTrack;

// Video resolutions - used for adjusting aspect ratio
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) CGSize localVideoSize;

// WebRTC client for the video call.
@property (nonatomic, strong) NINWebRTCClient* webrtcClient;

// This view is used to detect a tap outside the keyboard to close it
@property (nonatomic, strong) NINTouchView* tapRecognizerView;

// The text input box
@property (nonatomic, strong) IBOutlet UITextField* textInputField;

// Reference to the notifications observer that listens to new message -notifications.
@property (nonatomic, strong) id<NSObject> messagesObserver;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

// NSNotificationCenter observer for channel closed -events
@property (nonatomic, strong) id<NSObject> channelClosedObserver;

@end

@implementation NINChatViewController

#pragma mark - Private methods

-(void) adjustConstraintsForSize:(CGSize)size animate:(BOOL)animate {
    BOOL portrait = (size.height > size.width);

    if (portrait) {
        if (self.webrtcClient != nil) {
            // Video; In portrait we make the video cover about the top half of the screen
            self.videoContainerViewHeightConstraint.constant = size.height * 0.45;
        } else {
            // No video; get rid of the video view
            self.videoContainerViewHeightConstraint.constant = 0;
        }
        self.videoContainerViewHeightConstraint.active = YES;

        // No need for chat view height in portrait; the input container + video will dictate size
        self.chatViewHeightConstraint.active = NO;
        self.chatInputControlsViewHeightConstraint.constant = 100;
    } else {
        if (self.webrtcClient != nil) {
            // Video; in landscape we make video fullscreen ie. hide the chat view + input controls
            self.videoContainerViewHeightConstraint.active = YES;
            self.videoContainerViewHeightConstraint.constant = size.height;
            self.chatViewHeightConstraint.constant = 0;
            self.chatViewHeightConstraint.active = YES;
            self.chatInputControlsViewHeightConstraint.constant = 0;
        } else {
            // No video; get rid of the video view. the input container + video will dictate size
            self.videoContainerViewHeightConstraint.constant = 0;
            self.videoContainerViewHeightConstraint.active = YES;
            self.chatViewHeightConstraint.active = NO;
            self.chatInputControlsViewHeightConstraint.constant = 100;
        }
    }

    if (animate) {
        // Animate the changes
        [UIView animateWithDuration:0.3f animations:^{
            [self.view layoutIfNeeded];
        }];
    }

    // Prefer to show or hide status bar depending whether we have video or not
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void) pickupWithAnswer:(BOOL)answer {
    [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCPickup payloadDict:@{@"answer": @(answer)} completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Failed to send pick-up message: %@", error);
            //TODO error toast
        }
    }];
}

-(void) listenToWebRTCSignaling {
    NSCAssert(self.signalingObserver == nil, @"Cannot already have active observer");

    __weak typeof(self) weakSelf = self;

    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCCall]) {
            NSLog(@"Got WebRTC call");

            // Get rid of keyboard if any
            [weakSelf.textInputField resignFirstResponder];

            // Show answer / reject dialog for the incoming call
            [NINVideoCallConsentDialog showOnView:weakSelf.view forRemoteUser:note.userInfo[@"messageUser"] closedBlock:^(NINConsentDialogResult result) {
                [weakSelf pickupWithAnswer:(result == NINConsentDialogResultAccepted)];
            }];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCOffer]) {
            NSLog(@"Got WebRTC offer - initializing webrtc for video call (answer)");

            NSDictionary* offerPayload = note.userInfo[@"payload"];
            NSLog(@"Offer payload: %@", offerPayload);

            // Fetch our STUN / TURN server information
            [weakSelf.sessionManager beginICEWithCompletionCallback:^(NSError* error, NSArray<NINWebRTCServerInfo*>* stunServers, NSArray<NINWebRTCServerInfo*>* turnServers) {

                // Create a WebRTC client for the video call
                weakSelf.webrtcClient = [NINWebRTCClient clientWithSessionManager:weakSelf.sessionManager operatingMode:NINWebRTCClientOperatingModeCallee stunServers:stunServers turnServers:turnServers];

                NSLog(@"Starting WebRTC client..");
                weakSelf.webrtcClient.delegate = weakSelf;
                [weakSelf.webrtcClient startWithSDP:offerPayload[@"sdp"]];

                // Hide Close Chat button
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    weakSelf.closeChatButton.alpha = 0.0;
                }];

                // Show the video views
                [weakSelf adjustConstraintsForSize:weakSelf.view.bounds.size animate:YES];
            }];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCHangup]) {
            NSLog(@"Got WebRTC hang-up - closing the video call.");

            // Disconnect
            [weakSelf disconnectWebRTC];

            // Close the video view
            [weakSelf adjustConstraintsForSize:weakSelf.view.bounds.size animate:YES];
        }

        return NO;
    });
}

-(void) disconnectWebRTC {
    if (self.webrtcClient != nil) {
        NSLog(@"Disconnecting webrtc resources");

        // Clean up local video view
        if (self.localVideoTrack != nil) {
            [self.localVideoTrack removeRenderer:self.localVideoView];
        }
        self.localVideoTrack = nil;
        [self.localVideoView renderFrame:nil];

        // Clean up remote video view
        if (self.remoteVideoTrack != nil) {
            [self.remoteVideoTrack removeRenderer:self.remoteVideoView];
        }
        self.remoteVideoTrack = nil;
        [self.remoteVideoView renderFrame:nil];

        // Finally, disconnect the WebRTC client.
        [self.webrtcClient disconnect];
        self.webrtcClient = nil;

        // Show Close Chat button
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.closeChatButton.alpha = 1.0;
        }];
    }
}

-(void) orientationChanged:(NSNotification*)notification {
    [self videoView:self.remoteVideoView didChangeVideoSize:self.remoteVideoSize];
    [self videoView:self.localVideoView didChangeVideoSize:self.localVideoSize];
}

-(void) applicationWillResignActive:(UIApplication*)application {
    NSLog(@"applicationWillResignActive:");
    [self disconnectWebRTC];
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

-(IBAction) attachmentButtonPressed:(id)sender {
    NSLog(@"Attachment button pressed");

    UIImagePickerController* pickerController = [UIImagePickerController new];
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //TODO
    pickerController.mediaTypes = @[(NSString*)kUTTypeImage];
    pickerController.delegate = self;

    [self presentViewController:pickerController animated:YES completion:nil];
}

-(IBAction) hangupButtonPressed:(UIButton*)button {
    __weak typeof(self) weakSelf = self;

    [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCHangup payloadDict:@{} completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Failed to send hang-up: %@", error);
        }

        // Disconnect the WebRTC client
        [weakSelf disconnectWebRTC];

        // Hide the video views
        [weakSelf adjustConstraintsForSize:weakSelf.view.bounds.size animate:YES];
    }];
}


#pragma mark - From UIImagePickerControllerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {

    NSCAssert([info[UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage], @"Invalid media type received");

    UIImage* image = info[UIImagePickerControllerOriginalImage];
    NSData* imageData = UIImageJPEGRepresentation(image, 1.0);

    [self.sessionManager sendFile:@"image.jpeg" withData:imageData completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Failed to send image: %@", error);
            //TODO error? show toast
        }
    }];

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - From NINWebRTCClientDelegate

-(void) webrtcClient:(NINWebRTCClient *)client didGetError:(NSError *)error {
    NSLog(@"NINCHAT: didGetError: %@", error);

    [self disconnectWebRTC];

    [self adjustConstraintsForSize:self.view.bounds.size animate:YES];
}

-(void) webrtcClient:(NINWebRTCClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    NSLog(@"NINCHAT: didReceiveLocalVideoTrack: %@", localVideoTrack);

    if (self.localVideoTrack != nil) {
        [self.localVideoTrack removeRenderer:self.localVideoView];
        self.localVideoTrack = nil;
        [self.localVideoView renderFrame:nil];
    }

    self.localVideoTrack = localVideoTrack;
    [self.localVideoTrack addRenderer:self.localVideoView];
}

-(void) webrtcClient:(NINWebRTCClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    NSLog(@"NINCHAT: didReceiveRemoteVideoTrack: %@", remoteVideoTrack);

    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteVideoView];
}

#pragma mark - From RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    NSLog(@"NINCHAT: didChangeVideoSize: %@", NSStringFromCGSize(size));

    CGFloat containerWidth = self.videoContainerView.bounds.size.width;
    CGFloat containerHeight = self.videoContainerView.bounds.size.height;
    CGSize defaultAspectRatio = CGSizeMake(4, 3);
    CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;

    if (videoView == self.localVideoView) {
        NSLog(@"Adjusting local video view size");
        self.localVideoSize = size;

        // Fit the local video view inside a box sized proportionately to the video container
        CGRect videoRect = CGRectMake(0, 0, containerWidth / 3, containerHeight / 3);
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

        NSLog(@"Setting local video view size: %@", NSStringFromCGRect(videoFrame));

        self.localViewWidthConstraint.constant = videoFrame.size.width;
        self.localViewHeightConstraint.constant = videoFrame.size.height;
    } else {
        NSLog(@"Adjusting remote video view size");
        self.remoteVideoSize = size;

        // Fit the remote video view inside the view container with proper aspect ratio
        CGRect videoRect = self.videoContainerView.bounds;
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

        NSLog(@"Setting remote video view size: %@", NSStringFromCGRect(videoFrame));

        self.remoteViewWidthConstraint.constant = videoFrame.size.width;
        self.remoteViewHeightConstraint.constant = videoFrame.size.height;
    }

    // Animate the frame size change
    [UIView animateWithDuration:0.4f animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - From UIViewController

-(BOOL) prefersStatusBarHidden {
    // Prefer no status bar if video is active
    return (self.webrtcClient != nil);
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdChatToRating]) {
        NINRatingViewController* vc = segue.destinationViewController;
        vc.sessionManager = self.sessionManager;
    }
}

#pragma mark - From UIContentController

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self adjustConstraintsForSize:size animate:YES];
}

#pragma mark - From NINChatViewDataSource

- (NSInteger)numberOfMessagesForChatView:(NINChatView *)chatView {
    return self.sessionManager.channelMessages.count;
}

-(NINChannelMessage*) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index {
    return self.sessionManager.channelMessages[index];
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

    NSCAssert(self.sessionManager != nil, @"Must have session manager");
    NSCAssert(self.channelClosedObserver == nil, @"Must not have this observer already");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    __weak typeof(self) weakSelf = self;

    // Start listening to new messages
    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        [weakSelf.chatView newMessageWasAdded];

        return NO;
    });

    // Start listening to WebRTC signaling messages from the chat session manager
    [self listenToWebRTCSignaling];
    
    // Listen to channel closed -events
    self.channelClosedObserver = fetchNotification(kNINChannelClosedNotification, ^BOOL(NSNotification* note) {
        NSLog(@"Channel closed - showing rating view.");

        // Show the rating view
        [weakSelf performSegueWithIdentifier:kSegueIdChatToRating sender:nil];

        return YES;
    });

    // Set the constraints so that video is initially hidden
    [self adjustConstraintsForSize:self.view.bounds.size animate:NO];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
    self.messagesObserver = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self.signalingObserver];
    self.signalingObserver = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self.channelClosedObserver];
    self.channelClosedObserver = nil;
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    // Add tileable pattern image as the view background
    //TODO get from asset loader callback
    UIImage* bgImage = [UIImage imageNamed:@"chat_background_pattern" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    self.view.backgroundColor = [UIColor colorWithPatternImage:bgImage];

    [self.closeChatButton setButtonTitle:[self.sessionManager translation:kCloseChatText formatParams:nil]];

    __weak typeof(self) weakSelf = self;
    self.closeChatButton.pressedCallback = ^{
        NSLog(@"Close chat button pressed!");
        [weakSelf disconnectWebRTC];
        [weakSelf.sessionManager closeChat];
    };

    self.chatView.dataSource = self;

    self.remoteVideoView.delegate = self;
    self.localVideoView.delegate = self;

    // Give the local video view a slight border
    self.localVideoView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    self.localVideoView.layer.borderWidth = 1.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [self disconnectWebRTC];
}

@end
