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

static NSString* const kSegueIdChatToRating = @"ninchatsdk.segue.ChatToRatings";
static NSString* const kSegueIdChatToVideoCall = @"ninchatsdk.segue.ChatToVideoCall";

@interface NINChatViewController ()

// Reference to the notifications observer that listens to new message -notifications.
@property (nonatomic, strong) id<NSObject> messagesObserver;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

@end

@implementation NINChatViewController

#pragma mark - Private methods

-(void) sendButtonPressed:(id)sender {
    NSString* text = [self.toolbar clearText];
    NSLog(@"text to send: %@", text);

    [self.sessionManager sendTextMessage:text completion:^(NSError* _Nonnull error) {
        if (error != nil) {
            //TODO show error toast? check with UX people.
            NSLog(@"TODO: message failed to send - show error message");
        }
    }];
    /*
    if (text.length == 0) return;
    Message* message = [[Message alloc] init];
    message.text = text;
    message.senderID = 0;
    message.timestamp = [NSDate date].timeIntervalSince1970;
    [self.messages insertObject:message atIndex:0];
    [self.cellFactory updateTableNode:self.node.tableNode animated:YES withInsertions:@[[NSIndexPath indexPathForRow:0 inSection:0]] deletions:nil reloads:nil completion:nil];
     */
}

//#pragma mark - From MXMessageCellFactoryDataSource
//
//- (BOOL)cellFactory:(MXRMessageCellFactory *)cellFactory isMessageFromMeAtRow:(NSInteger)row {
//    return self.sessionManager.channelMessages[row].mine;
//}
//
//- (NSURL *)cellFactory:(MXRMessageCellFactory *)cellFactory avatarURLAtRow:(NSInteger)row {
//   // return [self cellFactory:cellFactory isMessageFromMeAtRow:row] ? nil : self.otherPersonsAvatar;
//    //TODO get the avatar from the message
//    return [NSURL URLWithString:@"https://ninchat-file-test-eu-central-1.s3-eu-central-1.amazonaws.com/u/5npsj2ag00m3g/5ogokj8m00m3g"];
//}
//
//- (NSTimeInterval)cellFactory:(MXRMessageCellFactory *)cellFactory timeIntervalSince1970AtRow:(NSInteger)row {
//    return [self.sessionManager.channelMessages[row].timestamp timeIntervalSince1970];
//}

#pragma mark - From UIViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdChatToVideoCall]) {
        NINVideoCallViewController* vc = segue.destinationViewController;
        vc.webrtcClient = sender;
    }
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak typeof(self) weakSelf = self;

    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        return NO;
    });

    // Start listening to WebRTC signaling messages from the chat session manager
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCOffer]) {
            NSLog(@"Got WebRTC offer - initializing webrtc for video call");

            NSData* payloadData = note.userInfo[@"payload"];
            NSError* jsonError = nil;
            NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:payloadData options:kNilOptions error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"Failed to parse JSON: %@", jsonError);
                return NO;
            }

            NSLog(@"Parsed payloadDict: %@", payloadDict);

            // Fetch our STUN / TURN server information
            [weakSelf.sessionManager beginICEWithCompletionCallback:^(NSError* error, NSArray<NINWebRTCServerInfo*>* stunServers, NSArray<NINWebRTCServerInfo*>* turnServers) {

                // Create a WebRTC client for the video call
                NINWebRTCClient* client = [NINWebRTCClient clientWithSessionManager:weakSelf.sessionManager operatingMode:NINWebRTCClientOperatingModeCallee stunServers:stunServers turnServers:turnServers];

                

                // Open the video call view
                [weakSelf performSegueWithIdentifier:kSegueIdChatToVideoCall sender:client];
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

//    self.node.tableNode.delegate = self;
//    self.node.tableNode.dataSource = self;
//    self.node.tableNode.allowsSelection = YES;
//
//    [self customizeCellFactory];
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
