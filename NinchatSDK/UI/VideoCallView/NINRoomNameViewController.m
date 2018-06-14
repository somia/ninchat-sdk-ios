//
//  NINRoomNameViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/06/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINRoomNameViewController.h"
#import "NINVideoCallViewController.h"

static NSString* const kSegueIdVideoChat = @"RoomNameToVideoCall";

@interface NINRoomNameViewController ()

@property (nonatomic, strong) IBOutlet UITextField* roomNameInput;

@end

@implementation NINRoomNameViewController

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NINVideoCallViewController* dest = (NINVideoCallViewController*)segue.destinationViewController;
    dest.roomName = self.roomNameInput.text;
}

-(IBAction) chatButtonPressed:(UIButton*)button {
    [self performSegueWithIdentifier:kSegueIdVideoChat sender:self];
}

@end
