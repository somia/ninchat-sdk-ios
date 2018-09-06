//
//  NINVideoCallConsentDialog.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AFNetworking;

#import "NINVideoCallConsentDialog.h"
#import "NINUtils.h"
#import "NINChannelUser.h"

@interface NINVideoCallConsentDialog ()

@property (nonatomic, strong) IBOutlet UIImageView* avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel* usernameLabel;
@property (nonatomic, strong) IBOutlet UIButton* acceptButton;
@property (nonatomic, strong) IBOutlet UIButton* rejectButton;

@property (nonatomic, copy) consentDialogClosedBlock closedBlock;
@property (nonatomic, strong) UIView* faderView;

@end

static const NSTimeInterval kAnimationDuration = 0.3;

@implementation NINVideoCallConsentDialog

// Util method for creating a constraint that matches given attribute exactly between two views
NSLayoutConstraint* constraint(UIView* view1, UIView* view2, NSLayoutAttribute attr) {
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attr relatedBy:NSLayoutRelationEqual toItem:view2 attribute:attr multiplier:1 constant:0];
}

#pragma mark - Private methods

// Loads the NINNavigationBar view from its xib
+(NINVideoCallConsentDialog*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle(self.class);
    NSArray* objects = [bundle loadNibNamed:@"NINVideoCallConsentDialog" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINVideoCallConsentDialog class]], @"Invalid class resource");

    return (NINVideoCallConsentDialog*)objects[0];
}

#pragma mark - Public methods

+(instancetype) showOnView:(UIView*)view forRemoteUser:(NINChannelUser*)user closedBlock:(consentDialogClosedBlock)closedBlock {
    NINVideoCallConsentDialog* d = [NINVideoCallConsentDialog loadViewFromNib];
    d.translatesAutoresizingMaskIntoConstraints = NO;
    d.closedBlock = closedBlock;

    [d.avatarImageView setImageWithURL:[NSURL URLWithString:user.iconURL]];
    d.usernameLabel.text = user.displayName;

    // Create a "fader" view to fade out the background a bit and constrain it to match the view
    d.faderView = [[UIView alloc] initWithFrame:view.bounds];
    d.faderView.translatesAutoresizingMaskIntoConstraints = NO;
    d.faderView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    d.faderView.alpha = 0.0;
    NSArray* faderConstraints = @[
                                  constraint(d.faderView, view, NSLayoutAttributeTop),
                                  constraint(d.faderView, view, NSLayoutAttributeRight),
                                  constraint(d.faderView, view, NSLayoutAttributeBottom),
                                  constraint(d.faderView, view, NSLayoutAttributeLeft)
                                  ];
    [view addSubview:d.faderView];
    [NSLayoutConstraint activateConstraints:faderConstraints];

    // Constrain the view to the given view's top edge
    NSArray* constraints = @[
                             constraint(d, view, NSLayoutAttributeTop),
                             constraint(d, view, NSLayoutAttributeRight),
                             constraint(d, view, NSLayoutAttributeLeft)
                             ];
    [view addSubview:d];
    [NSLayoutConstraint activateConstraints:constraints];

    // Animate us in
    d.transform = CGAffineTransformMakeTranslation(0, -d.bounds.size.height);
    [UIView animateWithDuration:kAnimationDuration animations:^{
        d.transform = CGAffineTransformIdentity;
        d.faderView.alpha = 0.6;
    } completion:^(BOOL finished) {

    }];

    return d;
}

#pragma mark - Private methods

-(void) closeWithResult:(NINConsentDialogResult)result {
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        self.faderView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.faderView removeFromSuperview];
        [self removeFromSuperview];

        self.closedBlock(result);
    }];
}

#pragma mark - IBAction handlers

-(IBAction) acceptButtonPressed:(UIButton*)button {
    [self closeWithResult:NINConsentDialogResultAccepted];
}

-(IBAction) rejectButtonPressed:(UIButton*)button {
    [self closeWithResult:NINConsentDialogResultRejected];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    // Make things round
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.acceptButton.layer.cornerRadius = self.acceptButton.bounds.size.height / 2;
    self.rejectButton.layer.cornerRadius = self.rejectButton.bounds.size.height / 2;
    self.rejectButton.layer.borderWidth = 1;
    self.rejectButton.layer.borderColor = [UIColor colorWithRed:0 green:138/255.0 blue:255/255.0 alpha:1].CGColor;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
