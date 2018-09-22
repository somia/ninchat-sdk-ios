//
//  NINChatView.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatView.h"
#import "NINChatBubbleCell.h"
#import "NINUtils.h"

@interface NINChatView () <UITableViewDelegate, UITableViewDataSource> {
    NSArray<NSIndexPath*>* _zeroIndexPathArray;
}

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@end

@implementation NINChatView

#pragma mark - Public methods

-(void) newMessageWasAdded {
    [self.tableView insertRowsAtIndexPaths:_zeroIndexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - From UITableViewDelegate

-(nonnull UITableViewCell*)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NINChatBubbleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatBubbleCell" forIndexPath:indexPath];

    __weak typeof(self) weakSelf = self;

    [cell populateWithMessage:[self.dataSource chatView:self messageAtIndex:indexPath.row]];
    cell.imagePressedCallback = ^(NINFileInfo* attachment, UIImage *image) {
        [weakSelf.delegate chatView:weakSelf imageSelected:image forAttachment:attachment];
    };

    return cell;
}

#pragma mark - From UITableViewDataSource

-(NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfMessagesForChatView:self];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    _zeroIndexPathArray = @[[NSIndexPath indexPathForRow:0 inSection:0]];

    NSBundle* bundle = findResourceBundle();
    NSCAssert(bundle != nil, @"Bundle not found");
    UINib* nib = [UINib nibWithNibName:@"NINChatBubbleCell" bundle:bundle];
    NSCAssert(nib != nil, @"NIB not found");
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NINChatBubbleCell"];

    // Rotate the table view 180 degrees; we will use it upside down
    self.tableView.transform = CGAffineTransformMakeRotation(M_PI);
}

@end

#pragma mark - NINEmbeddableNINChatView

@implementation NINEmbeddableChatView

// Loads the NINNavigationBar view from its xib
-(NINChatView*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINChatView" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINChatView class]], @"Invalid class resource");
    
    return (NINChatView*)objects[0];
}

// Substitutes the original view content (eg. from Storyboard) with contents of the xib
-(id) awakeAfterUsingCoder:(NSCoder *)aDecoder {
    NINChatView* newView = [self loadViewFromNib];

    newView.frame = self.frame;
    newView.autoresizingMask = self.autoresizingMask;
    newView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints;

    // Not to break the layout surrounding this view, we must copy the constraints over
    // to the newly loaded view
    for (NSLayoutConstraint* constraint in self.constraints) {
        id firstItem = (constraint.firstItem == self) ? newView : constraint.firstItem;
        id secondItem = (constraint.secondItem == self) ? newView : constraint.secondItem;

        [newView addConstraint:[NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
    }

    return newView;
}

@end
