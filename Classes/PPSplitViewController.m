//
//  PPSplitViewController.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 21.04.10.
//  Copyright 2010 Institute Of Immunology. All rights reserved.
//

#import "PPSplitViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+PPSubclassing.h"


#define kSplitViewDividerWidth 1.f


@interface PPSplitViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;
@property (nonatomic, strong) UIView *tabView;
@property (nonatomic, strong) UIImageView *logoView;

@property (nonatomic, readwrite, strong) UINavigationBar *leftTitleBar;
@property (nonatomic, readwrite, strong) UINavigationBar *rightTitleBar;

- (void)addLeftView;
- (void)addRightView;

@end


@implementation PPSplitViewController


- (void)viewDidUnload
{
	if ([_leftViewController isViewLoaded]) {
		[_leftViewController viewDidUnload];
	}
	if ([_rightViewController isViewLoaded]) {
		[_rightViewController viewDidUnload];
	}
	if ([_tabViewController isViewLoaded]) {
		[_tabViewController viewDidUnload];
	}
	
	self.containerView = nil;
	self.leftView = nil;
	self.rightView = nil;
	self.tabView = nil;
	self.logoView = nil;
	
	self.leftTitleBar = nil;
	self.rightTitleBar = nil;
}


- (id)init
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
		_usesFullLandscapeWidth = YES;
		_useCustomLeftTitleBar = YES;
		_useCustomRightTitleBar = YES;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}



#pragma mark - View Loading
- (void)loadView
{
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	self.view = [[UIView alloc] initWithFrame:appFrame];
	self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	self.view.opaque = YES;
	self.view.autoresizesSubviews = YES;
	
	// add background logo
	if (_logo) {
		self.logoView.image = _logo;
		[self.view addSubview:_logoView];
	}
	
	// container view
	self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	_containerView.opaque = NO;
	_containerView.backgroundColor = [UIColor clearColor];
	_containerView.autoresizesSubviews = YES;
	_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_containerView.layer.cornerRadius = 4.f;
	_containerView.clipsToBounds = YES;
	[self.view addSubview:_containerView];
	
	CGFloat naviHeight = 0.f;
	CGFloat halfWidth = roundf(0.5f * appFrame.size.width);
	
	// *** add left view and title (navigation) bar
	if (_useCustomLeftTitleBar) {
		naviHeight = 44.f;
		CGRect naviFrame = CGRectMake(0.f, 0.f, halfWidth - kSplitViewDividerWidth, naviHeight);
		self.leftTitleBar = [[UINavigationBar alloc] initWithFrame:naviFrame];
		_leftTitleBar.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[_containerView addSubview:_leftTitleBar];
	}
	
	appFrame.origin = CGPointZero;
	CGRect viewFrame = appFrame;
	viewFrame.origin.y = naviHeight;
	viewFrame.size.width = halfWidth - kSplitViewDividerWidth;
	viewFrame.size.height -= naviHeight;
	
	self.leftView = [[UIView alloc] initWithFrame:viewFrame];
	_leftView.backgroundColor = [UIColor whiteColor];
	_leftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
	
	[_containerView addSubview:_leftView];
	
	
	// *** add right view and title (navigation) bar
	naviHeight = 0.f;
	if (_useCustomRightTitleBar) {
		naviHeight = 44.f;
		CGRect naviFrame = CGRectMake(halfWidth, 0.f, halfWidth, naviHeight);
	//	naviFrame.size.width += kSplitViewDividerWidth;
		self.rightTitleBar = [[UINavigationBar alloc] initWithFrame:naviFrame];
		_rightTitleBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[_containerView addSubview:_rightTitleBar];
	}
	
	viewFrame = appFrame;
	viewFrame.origin.x = halfWidth;
	viewFrame.origin.y = naviHeight;
	viewFrame.size.width = halfWidth;
	viewFrame.size.height -= naviHeight;
	
	self.rightView = [[UIView alloc] initWithFrame:viewFrame];
	_rightView.backgroundColor = [UIColor whiteColor];
	_rightView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[_containerView addSubview:_rightView];
	
	// add real subviews
	[self addLeftView];
	[self addRightView];
	
	isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}


- (void)viewDidLayoutSubviews
{
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGFloat availWidth = 0.f;
	
	// landscape
	if (isLandscape) {
		availWidth = appFrame.size.height;
		CGFloat availHeight = appFrame.size.width;
		CGFloat tabWidth = 0.f;
		
		if (_usesFullLandscapeWidth) {
			_containerView.frame = CGRectMake(0.f, 0.f, availWidth - tabWidth, availHeight);
		}
		else {
			CGFloat sideOffset = roundf((availWidth - availHeight) / 2);
			_containerView.frame = CGRectMake(sideOffset, 0.f, availHeight, availHeight);
			availWidth = availHeight;
		}
	}
	
	// portrait
	else {
		availWidth = appFrame.size.width;
		CGFloat availHeight = appFrame.size.height;
		CGFloat tabHeight = 0.f;
		
		_containerView.frame = CGRectMake(0.f, 0.f, availWidth, availHeight - tabHeight);
	}
	
	// make sure the left and right views are absolutely correct
	CGFloat halfWidth = roundf(availWidth / 2);
	
	CGRect leftFrame = _leftView.frame;
	leftFrame.size.width = halfWidth - kSplitViewDividerWidth;
	_leftView.frame = leftFrame;
	
	CGRect rightFrame = _rightView.frame;
	rightFrame.origin.x = halfWidth;
	rightFrame.size.width = halfWidth;
	_leftView.frame = leftFrame;
}



#pragma mark - Rotation
/**
 *  iOS 6+
 */
- (NSUInteger)supportedInterfaceOrientations
{
	return 30;		// == UIInterfaceOrientationMaskAll;
}

/**
 *  iOS 5 and lower.
 *  TODO: Remove once only supporting iOS 6+
 */
- (BOOL)shouldAutomaticallyForwardRotationMethods
{
	return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	if (_usesFullLandscapeWidth) {
		_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		trackRotationAnimation = NO;
	}
	else {
		_containerView.autoresizingMask = UIViewAutoresizingNone;
		wasLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
		trackRotationAnimation = YES;
	}
	
	// inform subview controllers
	[_leftViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[_rightViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[_tabViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (trackRotationAnimation) {
		isLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
		
		if (wasLandscape != isLandscape) {
			[self viewDidLayoutSubviews];
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[_leftViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[_rightViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[_tabViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}



#pragma mark - View Controller Handling
- (void)setLeftViewController:(UIViewController *)newController
{
	if (newController != _leftViewController) {
		if (_leftViewController) {
			if ([_leftViewController isViewLoaded] && nil != [_leftViewController.view superview]) {
				[_leftViewController viewWillDisappear:NO];
				[_leftViewController.view removeFromSuperview];
				[_leftViewController viewDidDisappear:NO];
			}
			[_leftViewController setParentController:nil];
		}
		
		_leftViewController = newController;
		
		if ([self isViewLoaded] && _leftViewController) {
			[self addLeftView];
		}
	}
	
}

- (void)setRightViewController:(UIViewController *)newController
{
	if (newController != _rightViewController) {
		if (_rightViewController) {
			if ([_rightViewController isViewLoaded] && nil != [_rightViewController.view superview]) {
				[_rightViewController viewWillDisappear:NO];
				[_rightViewController.view removeFromSuperview];
				[_rightViewController viewDidDisappear:NO];
			}
			[_rightViewController setParentController:nil];
		}
		
		_rightViewController = newController;
		
		if ([self isViewLoaded] && _rightViewController) {
			[self addRightView];
		}
	}
	
}

- (UIView *)leftView
{
	if (!_leftView) {
		[self loadView];
	}
	return _leftView;
}

- (UIView *)rightView
{
	if (!_rightView) {
		[self loadView];
	}
	return _rightView;
}



#pragma mark The Logo
- (void)setLogo:(UIImage *)newLogo
{
	if (newLogo != _logo) {
		_logo = newLogo;
		
		if (_logo && [self isViewLoaded]) {
			self.logoView.image = _logo;
			[self.view insertSubview:_logoView atIndex:0];
		}
	}
}

- (UIImageView *)logoView
{
	if (!_logoView) {
		self.logoView = [[UIImageView alloc] initWithImage:_logo];
		CGSize sz = [_logoView frame].size;
		CGSize cs = [self.view bounds].size;
		_logoView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		_logoView.frame = CGRectMake(cs.width - sz.width - 5.f, cs.height - sz.height - 5.f, sz.width, sz.height);
	}
	return _logoView;
}



#pragma mark - Actions
- (void)addLeftView
{
	if (nil != _leftViewController) {
		UIView *addedView = _leftViewController.view;
		addedView.frame = _leftView.bounds;
		addedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[_leftViewController viewWillAppear:NO];
		[_leftView addSubview:addedView];
		[_leftViewController viewDidAppear:NO];
		
		// update navigation bar
		if (_leftTitleBar.topItem != _leftViewController.navigationItem) {
			[_leftTitleBar pushNavigationItem:_leftViewController.navigationItem animated:NO];
		}
	}
	else {
		DLog(@"No leftViewController");
	}
}

- (void)addRightView
{
	if (nil != _rightViewController) {
		UIView *addedView = _rightViewController.view;
		addedView.frame = _rightView.bounds;
		addedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[_rightViewController viewWillAppear:NO];
		[_rightView addSubview:addedView];
		[_rightViewController viewDidAppear:NO];
		
		// update navigation bar
		if (_rightTitleBar.topItem != _rightViewController.navigationItem) {
			[_rightTitleBar pushNavigationItem:_rightViewController.navigationItem animated:NO];
		}
	}
	else {
		DLog(@"No rightViewController");
	}
}


@end
