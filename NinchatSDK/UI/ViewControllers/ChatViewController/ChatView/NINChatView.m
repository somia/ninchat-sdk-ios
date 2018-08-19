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
