//
//  NINFullScreenImageViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINFullScreenImageViewController.h"
#import "NINFileInfo.h"

@interface NINFullScreenImageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIView* topBarView;
//@property (nonatomic, strong) IBOutlet UIView* topBarBackgroundView;
@property (nonatomic, strong) IBOutlet UILabel* fileNameLabel;

@property (nonatomic, strong) IBOutlet UIScrollView* scrollView;
@property (nonatomic, strong) IBOutlet UIImageView* fullScreenImageView;
//@property (nonatomic, strong) IBOutlet NSLayoutConstraint* contentWidthConstraint;
//@property (nonatomic, strong) IBOutlet NSLayoutConstraint* contentHeightConstraint;

@property (nonatomic, strong) UITapGestureRecognizer* tapRecognizer;

@end

static const NSTimeInterval kTopBarAnimationDuration = 0.3;

@implementation NINFullScreenImageViewController

#pragma mark - Private methods

-(void) tapped {
    CGAffineTransform newTransform = CGAffineTransformIdentity;
    CGFloat newAlpha = 1.0;

    // Toggle the top bar visibility
    if (CGAffineTransformIsIdentity(self.topBarView.transform)) {
        CGFloat amount = self.topBarView.frame.origin.y + self.topBarView.bounds.size.height;
        newTransform = CGAffineTransformMakeTranslation(0, -amount);
        newAlpha = 0.5;
    }

    // Animate it
    [UIView animateWithDuration:kTopBarAnimationDuration animations:^{
        self.topBarView.transform = newTransform;
        self.topBarView.alpha = newAlpha;
    }];
}

#pragma mark - IBAction handlers

-(IBAction) closeButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - From UIScrollViewDelegate

-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.fullScreenImageView;
}

#pragma mark - From UIViewController

-(BOOL) prefersStatusBarHidden {
    return YES;
}

#pragma mark - Lifecycle, etc.

- (void)viewDidLoad {
    [super viewDidLoad];

    NSCAssert(self.image != nil, @"Opened with nil image");
    NSCAssert(self.attachment != nil, @"Opened with nil attachment");

    self.fullScreenImageView.image = self.image;
    self.fileNameLabel.text = self.attachment.name;

    // Figure out the max zoom ratio required by comparing the image size to the screen size
    CGSize windowSize = UIApplication.sharedApplication.keyWindow.bounds.size;
    CGSize imageSize = self.image.size;

    CGFloat windowDimension = MAX(windowSize.width, windowSize.height);
    CGFloat imageDimension = MAX(imageSize.width, imageSize.height);

    CGFloat ratio = MAX(1.0, (imageDimension / windowDimension)) * 1.5;
    self.scrollView.maximumZoomScale = ratio;

    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [self.fullScreenImageView addGestureRecognizer:self.tapRecognizer];
}

@end
