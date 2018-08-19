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

@interface NINChatViewController ()

/** Reference to the notifications observer that listens to new message -notifications. */
@property (nonatomic, strong) id<NSObject> messagesObserver;

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

#pragma mark - Lifecycle etc.

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
/*
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.sessionManager sendMessage:@"Ninchat iOS SDK says hi" completion:^(NSError* error) {
            if (error != nil) {
                NSLog(@"Error sending message: %@", error);
                return;
            }

            NSLog(@"Message sent.");
        }];
    });
*/
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak typeof(self) weakSelf = self;

    self.messagesObserver = fetchNotification(kNewChannelMessageNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSLog(@"There is a new message");

        // Insert the new message chat bubble as the newest entry
//        [weakSelf.cellFactory updateTableNode:weakSelf.node.tableNode animated:YES withInsertions:@[[NSIndexPath indexPathForRow:0 inSection:0]] deletions:nil reloads:nil completion:nil];

        return NO;
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

//
//-(instancetype) init {
////    MXRMessengerInputToolbar* toolbar = [[MXRMessengerInputToolbar alloc] initWithFont:[UIFont systemFontOfSize:16.0f] placeholder:@"Type a message" tintColor:[UIColor mxr_fbMessengerBlue]];
////    self = [super initWithToolbar:toolbar];
//    if (self != nil) {
//        self.title = @"chat test";
//
//        // add extra buttons to toolbar
////        MXRMessengerIconButtonNode* addPhotosBarButtonButtonNode = [MXRMessengerIconButtonNode buttonWithIcon:[[MXRMessengerPlusIconNode alloc] init] matchingToolbar:self.toolbar];
////        [addPhotosBarButtonButtonNode addTarget:self action:@selector(tapAddPhotos:) forControlEvents:ASControlNodeEventTouchUpInside];
////        self.toolbar.leftButtonsNode = addPhotosBarButtonButtonNode;
//
//        [self.toolbar.defaultSendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:ASControlNodeEventTouchUpInside];
//    }
//
//    return self;
//}

@end
