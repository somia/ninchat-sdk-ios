//
//  ChatViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import MobileCoreServices;
@import AVFoundation;
@import AVKit;
@import Photos;

@import Libjingle;

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
#import "NINFullScreenImageViewController.h"
#import "NINToast.h"
#import "NINFileInfo.h"
#import "NINExpandingTextView.h"
#import "NINChoiceDialog.h"
#import "NINPermissions.h"
#import "NINConfirmCloseChatDialog.h"

// Segue IDs
static NSString* const kSegueIdChatToRating = @"ninchatsdk.segue.ChatToRatings";
static NSString* const kSegueIdChatToFullScreenImage = @"ninchatsdk.segue.ChatToFullScreenImage";

static const NSTimeInterval kAnimationDuration = 0.3;

// UI (Localizable) strings
static NSString* const kCloseChatText = @"Close chat";
static NSString* const kTextInputPlaceholderText = @"Enter your message";

@interface NINChatViewController () <NINChatViewDataSource, NINChatViewDelegate, NINWebRTCClientDelegate, RTCEAGLVideoViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>

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

// Top alignment constraint of the chst input controls view - used to hide the input controls
@property (nonatomic, strong) NSLayoutConstraint* chatInputControlsTopAlignConstraint;

// The chat messages view
@property (nonatomic, strong) IBOutlet NINChatView* chatView;

// The close chat button
@property (nonatomic, strong) IBOutlet NINCloseChatButton* closeChatButton;

// Hang up video call button
@property (nonatomic, strong) IBOutlet UIButton* hangupButton;

// Audio mute / unmute button
@property (nonatomic, strong) IBOutlet UIButton* microphoneEnabledButton;

// Local video enable / disable
@property (nonatomic, strong) IBOutlet UIButton* cameraEnabledButton;

// The input controls containere view
@property (nonatomic, strong) IBOutlet UIView* inputControlsContainerView;

// The text input box
@property (nonatomic, strong) IBOutlet NINExpandingTextView* textInput;

// Placeholder text label for the text input box
@property (nonatomic, strong) IBOutlet UILabel* textInputPlaceholderLabel;

// Add attachment -button
@property (nonatomic, strong) IBOutlet UIButton* attachmentButton;

// Send message button
@property (nonatomic, strong) IBOutlet UIButton* sendMessageButton;

// Width constraint for the send message button
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* sendMessageButtonWidthConstraint;

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

// Reference to the notifications observer that listens to new message -notifications.
@property (nonatomic, strong) id<NSObject> messagesObserver;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

// NSNotificationCenter observer for user is ryping into the chat
@property (nonatomic, strong) id<NSObject> typingObserver;

@end

@implementation NINChatViewController

#pragma mark - Private methods

-(void) updateTextInputPlaceholder {
    // Show or hide the placeholder text when entering text into the input
    CGFloat newPlaceholderAlpha = (self.textInput.text.length == 0) ? 1 : 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.textInputPlaceholderLabel.alpha = newPlaceholderAlpha;
    }];
}

-(void) closeChatButtonPressed {
    NSLog(@"Close chat button pressed!");

    __weak typeof(self) weakSelf = self;

    [NINConfirmCloseChatDialog showOnView:self.view sessionManager:self.sessionManager closedBlock:^(NINConfirmCloseChatDialogResult result) {
        if (result == NINConfirmCloseChatDialogResultClose) {
            [weakSelf disconnectWebRTC];
            [weakSelf performSegueWithIdentifier:kSegueIdChatToRating sender:nil];
        }
    }];
}

-(void) applyAssetOverrides {
    NSString* sendButtonTitle = self.sessionManager.siteConfiguration[@"default"][@"sendButtonText"];
    [self updateSendMessageButtonWithText:sendButtonTitle];

    UIImage* attachmentIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconTextareaAttachment];
    if (attachmentIcon != nil) {
        [self.attachmentButton setImage:attachmentIcon forState:UIControlStateNormal];
    }

    UIImage* hangupIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconVideoHangup];
    if (hangupIcon != nil) {
        [self.hangupButton setImage:hangupIcon forState:UIControlStateNormal];
    }

    UIImage* micOnIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconVideoMicrophoneOn];
    if (micOnIcon != nil) {
        [self.microphoneEnabledButton setImage:micOnIcon forState:UIControlStateNormal];
    }

    UIImage* micOffIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconVideoMicrophoneOff];
    if (micOffIcon != nil) {
        [self.microphoneEnabledButton setImage:micOffIcon forState:UIControlStateSelected];
    }

    UIImage* cameraOnIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconVideoCameraOn];
    if (cameraOnIcon != nil) {
        [self.cameraEnabledButton setImage:cameraOnIcon forState:UIControlStateNormal];
    }

    UIImage* cameraOffIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconVideoCameraOff];
    if (cameraOffIcon != nil) {
        [self.cameraEnabledButton setImage:cameraOffIcon forState:UIControlStateSelected];
    }

    UIColor* inputTextColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetKeyTextareaText];
    if (inputTextColor != nil) {
        self.textInput.textColor = inputTextColor;
    }

    // UI strings
    NSString* enterYourMessage = [self.sessionManager translation:kTextInputPlaceholderText formatParams:nil];
    if (enterYourMessage != nil) {
        self.textInputPlaceholderLabel.text = enterYourMessage;
    }
}

// Aligns (or cancels existing alignment) the input control container view's top
// to the screen bottom to hide the controls.
-(void) alignInputControlsTopToScreenBottom:(BOOL)align {
    if (align) {
        if (self.chatInputControlsTopAlignConstraint == nil) {
            self.chatInputControlsTopAlignConstraint = [self.inputControlsContainerView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor];
            self.chatInputControlsTopAlignConstraint.active = YES;
        }
    } else {
        self.chatInputControlsTopAlignConstraint.active = NO;
        self.chatInputControlsTopAlignConstraint = nil;
    }
}

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
        [self alignInputControlsTopToScreenBottom:NO];
    } else {
        if (self.webrtcClient != nil) {
            // Video; in landscape we make video fullscreen ie. hide the chat view + input controls
            self.videoContainerViewHeightConstraint.active = YES;
            self.videoContainerViewHeightConstraint.constant = size.height;
            self.chatViewHeightConstraint.constant = 0;
            self.chatViewHeightConstraint.active = YES;
            [self alignInputControlsTopToScreenBottom:YES];
        } else {
            // No video; get rid of the video view. the input container and
            // video (0-height) will dictate size
            self.videoContainerViewHeightConstraint.constant = 0;
            self.videoContainerViewHeightConstraint.active = YES;
            self.chatViewHeightConstraint.active = NO;
            [self alignInputControlsTopToScreenBottom:NO];
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
            [NINToast showWithErrorMessage:@"Failed to send WebRTC pickup message" callback:nil];
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
            [weakSelf.textInput resignFirstResponder];

            // Show answer / reject dialog for the incoming call
            [NINVideoCallConsentDialog showOnView:weakSelf.view forRemoteUser:note.userInfo[@"messageUser"] sessionManager:weakSelf.sessionManager closedBlock:^(NINConsentDialogResult result) {
                [weakSelf pickupWithAnswer:(result == NINConsentDialogResultAccepted)];
            }];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCOffer]) {
            NSLog(@"Got WebRTC offer - initializing webrtc for video call (answer)");

            NSDictionary* offerPayload = note.userInfo[@"payload"];
//            NSLog(@"Offer payload: %@", offerPayload);

            // Fetch our STUN / TURN server information
            [weakSelf.sessionManager beginICEWithCompletionCallback:^(NSError* error, NSArray<NINWebRTCServerInfo*>* stunServers, NSArray<NINWebRTCServerInfo*>* turnServers) {

                // Create a WebRTC client for the video call
                weakSelf.webrtcClient = [NINWebRTCClient clientWithSessionManager:weakSelf.sessionManager operatingMode:NINWebRTCClientOperatingModeCallee stunServers:stunServers turnServers:turnServers];

//                NSLog(@"Starting WebRTC client..");
                weakSelf.webrtcClient.delegate = weakSelf;
                [weakSelf.webrtcClient startWithSDP:offerPayload[@"sdp"]];

                // Hide Close Chat button
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    weakSelf.closeChatButton.alpha = 0.0;
                }];

                // Reset the video control buttons
                weakSelf.microphoneEnabledButton.selected = NO;
                weakSelf.cameraEnabledButton.selected = NO;

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
    NSCAssert([NSThread isMainThread], @"Must only be called on the main thread");

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

-(void) sendTextMessage {
    NSString* text = [self.textInput.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.textInput.text = nil;
    [self.textInput resignFirstResponder];
    [self updateTextInputPlaceholder];

    if ([text length] > 0) {
        [self.sessionManager sendTextMessage:text completion:^(NSError* _Nonnull error) {
            if (error != nil) {
                NSLog(@"TODO: message failed to send - show error message");
                [NINToast showWithErrorMessage:@"Failed to send message" callback:nil];
            }
        }];
    }
}

-(void) updateSendMessageButtonWithText:(NSString*)sendMessageButtonTitle {
    if (sendMessageButtonTitle == nil) {
        // No button title; use simply the image icon
        UIImage* buttonImage = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconTextareaSubmitButtonIcon];
        if (buttonImage != nil) {
            [self.sendMessageButton setImage:buttonImage forState:UIControlStateNormal];
        }
    } else {
        // Button has title; use border background image
        self.sendMessageButtonWidthConstraint.active = NO;
        [self.sendMessageButton setImage:nil forState:UIControlStateNormal];
        [self.sendMessageButton setTitle:sendMessageButtonTitle forState:UIControlStateNormal];
        self.sendMessageButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 15);

        // Asset overrides
        UIImage* bgImage = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyTextareaSubmitButton];
        if (bgImage == nil) {
            bgImage = [UIImage imageNamed:@"icon_send_message_border" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
        }
        [self.sendMessageButton setBackgroundImage:bgImage forState:UIControlStateNormal];

        UIColor* titleColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetKeyTextareaSubmitText];
        if (titleColor != nil) {
            [self.sendMessageButton setTitleColor:titleColor forState:UIControlStateNormal];
        }
    }
}

#pragma mark - IBAction handlers

-(IBAction) sendButtonPressed:(id)sender {
    [self sendTextMessage];
}

-(IBAction) attachmentButtonPressed:(id)sender {
    NSLog(@"Attachment button pressed");

    // Get rid of the keyboard should it exist
    [self.textInput resignFirstResponder];

    __weak typeof(self) weakSelf = self;

    void (^showPicker)(UIImagePickerControllerSourceType) = ^(UIImagePickerControllerSourceType sourceType) {
        UIImagePickerController* pickerController = [UIImagePickerController new];
        pickerController.sourceType = sourceType;
        pickerController.mediaTypes = @[(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie];
        pickerController.allowsEditing = YES;
        pickerController.delegate = weakSelf;

        [weakSelf presentViewController:pickerController animated:YES completion:nil];
    };

    NSArray* sourceTypes = @[@(UIImagePickerControllerSourceTypeCamera), @(UIImagePickerControllerSourceTypePhotoLibrary)];
    NSArray* sourceTitles = @[@"Camera", @"Photo Library"];

    [NINChoiceDialog showWithOptionTitles:sourceTitles completion:^(BOOL canceled, NSInteger selectedIndex) {
        if (!canceled) {
            UIImagePickerControllerSourceType sourceType = [sourceTypes[selectedIndex] integerValue];
            if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
                [NINToast showWithErrorMessage:@"That source type is not available on this device." callback:nil];
                return;
            }

            if (sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
                checkPhotoLibraryPermission(^(NSError* error) {
                    if (error != nil) {
                        [NINToast showWithErrorMessage:@"Photo Library access is denied." callback:nil];
                    } else {
                        showPicker(sourceType);
                    }
                });
            } else {
                checkVideoPermission(^(NSError* error) {
                    if (error != nil) {
                        [NINToast showWithErrorMessage:@"Camera access is denied." callback:nil];
                    } else {
                        showPicker(sourceType);
                    }
                });
            }
        }
    }];
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

-(IBAction) audioMuteButtonPressed:(UIButton*)button {
    if (button.selected) {
        [self.webrtcClient unmuteLocalAudio];
        [self.sessionManager.ninchatSession sdklog:@"Audio unmuted."];
    } else {
        [self.webrtcClient muteLocalAudio];
        [self.sessionManager.ninchatSession sdklog:@"Audio muted."];
    }

    button.selected = !button.selected;
}

-(IBAction) cameraEnabledButtonPressed:(UIButton*)button {
    if (button.selected) {
        [self.webrtcClient enableLocalVideo];
        [self.sessionManager.ninchatSession sdklog:@"Video enabled."];
    } else {
        [self.webrtcClient disableLocalVideo];
        [self.sessionManager.ninchatSession sdklog:@"Video disabled."];
    }

    button.selected = !button.selected;
}

#pragma mark - From UITextViewDelegate

-(void) textViewDidChange:(UITextView *)textView {
    [self updateTextInputPlaceholder];
}

//-(BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text {
//    if ([text isEqualToString:@"\n"]){
//        // Send button was pressed on the keyboard
//        [self sendTextMessage];
//        return NO;
//    } else {
//        return YES;
//    }
//}

#pragma mark - From UIImagePickerControllerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString*,id> *)info {

    runInBackgroundThread(^{
        NSString* fileName = @"photo.jpg";

        // Photos from photo library have file names; extract it
        if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            NSURL* referenceURL = info[UIImagePickerControllerReferenceURL];
            PHAsset* phAsset = [[PHAsset fetchAssetsWithALAssetURLs:@[referenceURL] options:nil] lastObject];
            fileName = [phAsset valueForKey:@"filename"];
        }

        NSString* mediaType = (NSString*)info[UIImagePickerControllerMediaType];

        if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
            UIImage* image = info[UIImagePickerControllerEditedImage];
            NSData* imageData = UIImageJPEGRepresentation(image, 1.0);

            [self.sessionManager sendFileWithFilename:fileName withData:imageData completion:^(NSError* error) {
                NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

                if (error != nil) {
                    [NINToast showWithErrorMessage:@"Failed to send image file" callback:nil];
                }
            }];
        } else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
            // Read the video file into RAM (hoping it will fit).
            NSURL* videoURL = info[UIImagePickerControllerMediaURL];
            NSLog(@"videoURL: %@", videoURL.absoluteString);
            //TODO can we use this API or should we use this:
            //https://developer.apple.com/documentation/foundation/nsinputstream/1564838-inputstreamwithurl
            NSData* videoFileData = [NSData dataWithContentsOfURL:videoURL];
            NSLog(@"Read %lu bytes of the video file.", (unsigned long)videoFileData.length);

            [self.sessionManager sendFileWithFilename:fileName withData:videoFileData completion:^(NSError* error) {
                NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

                if (error != nil) {
                    //TODO localize
                    [NINToast showWithErrorMessage:@"Failed to send video file." callback:nil];
                }
            }];
        } else {
            NSCAssert(false, @"Invalid media type!");
        }
    });

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
//    NSLog(@"NINCHAT: didChangeVideoSize: %@", NSStringFromCGSize(size));

    CGFloat containerWidth = self.videoContainerView.bounds.size.width;
    CGFloat containerHeight = self.videoContainerView.bounds.size.height;
    CGSize defaultAspectRatio = CGSizeMake(4, 3);
    CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;

    if (videoView == self.localVideoView) {
//        NSLog(@"Adjusting local video view size");
        self.localVideoSize = size;

        // Fit the local video view inside a box sized proportionately to the video container
        CGRect videoRect = CGRectMake(0, 0, containerWidth / 3, containerHeight / 3);
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

//        NSLog(@"Setting local video view size: %@", NSStringFromCGRect(videoFrame));

        self.localViewWidthConstraint.constant = videoFrame.size.width;
        self.localViewHeightConstraint.constant = videoFrame.size.height;
    } else {
//        NSLog(@"Adjusting remote video view size");
        self.remoteVideoSize = size;

        // Fit the remote video view inside the view container with proper aspect ratio
        CGRect videoRect = self.videoContainerView.bounds;
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

//        NSLog(@"Setting remote video view size: %@", NSStringFromCGRect(videoFrame));

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
    } else if ([segue.identifier isEqualToString:kSegueIdChatToFullScreenImage]) {
        NINFullScreenImageViewController* vc = segue.destinationViewController;
        NSDictionary* dict = (NSDictionary*)sender;
        vc.image = dict[@"image"];
        vc.attachment = dict[@"attachment"];
    }
}

#pragma mark - From UIContentController

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self.textInput resignFirstResponder];

    [self adjustConstraintsForSize:size animate:YES];
}

#pragma mark - From NINChatViewDataSource

- (NSInteger)numberOfMessagesForChatView:(NINChatView *)chatView {
    return self.sessionManager.chatMessages.count;
}

-(NINChannelMessage*) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index {
    return self.sessionManager.chatMessages[index];
}

#pragma mark - From NINChatViewDelegate

-(void) chatView:(NINChatView *)chatView imageSelected:(UIImage*)image forAttachment:(NINFileInfo*)attachment {
    if (attachment.isImage) {
        // Open the selected image in a full-screen image view
        [self performSegueWithIdentifier:kSegueIdChatToFullScreenImage sender:@{@"image": image, @"attachment": attachment}];
    } else if (attachment.isVideo) {
        // Open the selected video in a full-screen player
        AVPlayerViewController* playerController = [AVPlayerViewController new];
        playerController.player = [AVPlayer playerWithURL:[NSURL URLWithString:attachment.url]];
        [playerController.player play];
        [self presentViewController:playerController animated:YES completion:nil];
    }
}

-(void) closeChatRequestedByChatView:(NINChatView*)chatView {
    [self closeChatButtonPressed];
}

#pragma mark - From NINBaseViewController

-(void) keyboardWillShow:(NSNotification *)notification {
    [super keyboardWillShow:notification];

    if (self.tapRecognizerView == nil) {
        __weak typeof(self) weakSelf = self;
        self.tapRecognizerView = [[NINTouchView alloc] initWithFrame:self.chatView.bounds];
        self.tapRecognizerView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.chatView addSubview:self.tapRecognizerView];
        [NSLayoutConstraint activateConstraints:constrainToMatch(self.tapRecognizerView, self.chatView)];

        self.tapRecognizerView.touchCallback = ^{
            // Get rid of the keyboard
            [weakSelf.textInput resignFirstResponder];
        };
    }

    [self.sessionManager setIsWriting:YES completion:^(NSError* error) {}];
}

-(void) keyboardWillHide:(NSNotification *)notification {
    [super keyboardWillHide:notification];

    [self.tapRecognizerView removeFromSuperview];
    self.tapRecognizerView = nil;

    [self.sessionManager setIsWriting:NO completion:^(NSError* error) {}];
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSCAssert(self.sessionManager != nil, @"Must have session manager");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    __weak typeof(self) weakSelf = self;

    // Start listening to new messages
    self.messagesObserver = fetchNotification(kChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSNumber* removedAtIndex = note.userInfo[@"removedMessageAtIndex"];
        if (removedAtIndex == nil) {
            [weakSelf.chatView newMessageWasAdded];
        } else {
            [weakSelf.chatView messageWasRemovedAtIndex:removedAtIndex.integerValue];
        }

        return NO;
    });

    // Start listening to WebRTC signaling messages from the chat session manager
    [self listenToWebRTCSignaling];

    // Set the constraints so that video is initially hidden
    [self adjustConstraintsForSize:self.view.bounds.size animate:NO];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
    self.messagesObserver = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self.signalingObserver];
    self.signalingObserver = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self.typingObserver];
    self.typingObserver = nil;
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

-(void) inputControlsContainerTapped:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Make text input the first responder (= input focus + open keyboard)
        [self.textInput becomeFirstResponder];
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    // Pass the session reference to chat view for handling the asset overrides
    self.chatView.session = self.sessionManager.ninchatSession;

    // Add tileable pattern image as the view background
    UIImage* bgImage = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyChatBackground];
    if (bgImage == nil) {
        bgImage = [UIImage imageNamed:@"chat_background_pattern" inBundle:findResourceBundle() compatibleWithTraitCollection:nil];
    }
    self.view.backgroundColor = [UIColor colorWithPatternImage:bgImage];

    [self.closeChatButton setButtonTitle:[self.sessionManager translation:kCloseChatText formatParams:nil]];
    [self.closeChatButton overrideAssetsWithSession:self.sessionManager.ninchatSession];

    __weak typeof(self) weakSelf = self;
    self.closeChatButton.pressedCallback = ^{
        [weakSelf closeChatButtonPressed];
    };

    self.chatView.dataSource = self;
    self.chatView.delegate = self;

    self.remoteVideoView.delegate = self;
    self.localVideoView.delegate = self;

    // Add tap gesture recognizer for the input controls container view
    UIGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputControlsContainerTapped:)];
    [self.inputControlsContainerView addGestureRecognizer:tapRecognizer];

    // Give the local video view a slight border
    self.localVideoView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    self.localVideoView.layer.borderWidth = 1.0;

    // Make buttons round
    self.hangupButton.layer.cornerRadius = self.hangupButton.bounds.size.height / 2;
    self.microphoneEnabledButton.layer.cornerRadius = self.microphoneEnabledButton.bounds.size.height / 2;
    self.cameraEnabledButton.layer.cornerRadius = self.cameraEnabledButton.bounds.size.height / 2;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    // Apply asset overrides
    [self applyAssetOverrides];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [self disconnectWebRTC];
}

@end
