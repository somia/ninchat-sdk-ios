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

@interface NINChatView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@end

@implementation NINChatView

#pragma mark - From UITableViewDelegate

-(nonnull UITableViewCell*)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NINChatBubbleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NINChatBubbleCell" forIndexPath:indexPath];

    //TODO

    return cell;
}

#pragma mark - From UITableViewDataSource

-(NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //TODO
    return 3;
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    NSBundle* bundle = findResourceBundle(self.class, @"NINChatBubbleCell", @"nib");
    NSCAssert(bundle != nil, @"Bundle not found");
    UINib* nib = [UINib nibWithNibName:@"NINChatBubbleCell" bundle:bundle];
    NSCAssert(nib != nil, @"NIB not found");
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NINChatBubbleCell"];
}

@end

#pragma mark - NINEmbeddableNINChatView

@implementation NINEmbeddableChatView

// Loads the NINNavigationBar view from its xib
-(NINChatView*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle([NINChatView class], @"NINChatView", @"nib");
    NSArray* objects = [bundle loadNibNamed:@"NINChatView" owner:nil options:nil];

    return (NINChatView*)objects[0];
}

// Substitutes the original view content (eg. from Storyboard) with contents of the xib
-(id) awakeAfterUsingCoder:(NSCoder *)aDecoder {
    UIView* newView = [self loadViewFromNib];
    newView.translatesAutoresizingMaskIntoConstraints = NO;

    // Not to break the layout surrounding this view, we must copy the constraints over
    // to the newly loaded view
    for (NSLayoutConstraint* constraint in self.constraints) {
        if (constraint.secondItem != nil) {
            [newView addConstraint:[NSLayoutConstraint constraintWithItem:newView attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:newView attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
        } else {
            [newView addConstraint:[NSLayoutConstraint constraintWithItem:newView attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:constraint.constant]];
        }
    }

    return newView;
}

@end