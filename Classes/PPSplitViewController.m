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

#define USE_TWO_PART_ANIMATION 0


@interface PPSplitViewController ()

@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) UIView *leftView;
@property (nonatomic, retain) UIView *rightView;
@property (nonatomic, retain) UIView *tabView;
@property (nonatomic, retain) UIImageView *logoView;

@property (nonatomic, readwrite, retain) UINavigationBar *leftTitleBar;
@property (nonatomic, readwrite, retain) UINavigationBar *rightTitleBar;

- (void) addLeftView;
- (void) addRightView;
- (void) layoutViews;

@end


@implementation PPSplitViewController

@dynamic leftViewController;
@dynamic rightViewController;
@synthesize tabViewController;
@dynamic logo;
@dynamic logoView;
@synthesize usesFullLandscapeWidth;

@synthesize containerView;
@dynamic leftView;
@dynamic rightView;
@synthesize tabView;

@synthesize useCustomLeftTitleBar;
@synthesize useCustomRightTitleBar;
@synthesize leftTitleBar;
@synthesize rightTitleBar;


- (void) dealloc
{
	self.leftViewController = nil;
	self.rightViewController = nil;
	self.tabViewController = nil;
	self.logo = nil;
	self.logoView = nil;
	
	self.containerView = nil;
	self.leftView = nil;
	self.rightView = nil;
	self.tabView = nil;
	
	self.leftTitleBar = nil;
	self.rightTitleBar = nil;
	
	[super dealloc];
}

- (void) viewDidUnload
{
	if ([leftViewController isViewLoaded]) {
		[leftViewController viewDidUnload];
	}
	if ([rightViewController isViewLoaded]) {
		[rightViewController viewDidUnload];
	}
	if ([tabViewController isViewLoaded]) {
		[tabViewController viewDidUnload];
	}
	
	self.containerView = nil;
	self.leftView = nil;
	self.rightView = nil;
	self.tabView = nil;
	self.logoView = nil;
	
	self.leftTitleBar = nil;
	self.rightTitleBar = nil;
}


- (id) init
{
	if (self = [super initWithNibName:nil bundle:nil]) {
		usesFullLandscapeWidth = YES;
		useCustomLeftTitleBar = YES;
		useCustomRightTitleBar = YES;
	}
	return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}
#pragma mark -



#pragma mark View Loading
- (void) loadView
{
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	self.view = [[[UIView alloc] initWithFrame:appFrame] autorelease];
	self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	self.view.opaque = YES;
	self.view.autoresizesSubviews = YES;
	
	// add background logo
	if (logo) {
		self.logoView.image = logo;
		[self.view addSubview:logoView];
	}
	
	// container view
	self.containerView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
	containerView.opaque = NO;
	containerView.backgroundColor = [UIColor clearColor];
	containerView.autoresizesSubviews = YES;
	containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	containerView.layer.cornerRadius = 4.f;
	containerView.clipsToBounds = YES;
	[self.view addSubview:containerView];
	
	CGFloat dividerWidth = 1.f;
	CGFloat naviHeight = 0.f;
	CGFloat halfWidth = roundf(0.5 * appFrame.size.width);
	
	// *** add left view and title (navigation) bar
	if (useCustomLeftTitleBar) {
		naviHeight = 44.f;
		CGRect naviFrame = CGRectMake(0.f, 0.f, halfWidth - dividerWidth, naviHeight);
		self.leftTitleBar = [[[UINavigationBar alloc] initWithFrame:naviFrame] autorelease];
		leftTitleBar.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[containerView addSubview:leftTitleBar];
	}
	
	CGRect viewFrame = appFrame;
	viewFrame.origin.y = naviHeight;
	viewFrame.size.width = halfWidth - dividerWidth;
	viewFrame.size.height -= naviHeight;
	
	self.leftView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
	leftView.backgroundColor = [UIColor whiteColor];
	leftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
	
	[containerView addSubview:leftView];
	
	
	// *** add right view and title (navigation) bar
	naviHeight = 0.f;
	if (useCustomRightTitleBar) {
		naviHeight = 44.f;
		CGRect naviFrame = CGRectMake(halfWidth, 0.f, halfWidth, naviHeight);
		naviFrame.size.width += dividerWidth;
		self.rightTitleBar = [[[UINavigationBar alloc] initWithFrame:naviFrame] autorelease];
		rightTitleBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[containerView addSubview:rightTitleBar];
	}
	
	viewFrame = appFrame;
	viewFrame.origin.x = halfWidth;
	viewFrame.origin.y = naviHeight;
	viewFrame.size.width = halfWidth;
	viewFrame.size.height -= naviHeight;
	
	self.rightView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
	rightView.backgroundColor = [UIColor whiteColor];
	rightView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
	
	[containerView addSubview:rightView];
	
	// add real subviews
	[self addLeftView];
	[self addRightView];
	
	isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}


- (void) layoutViews
{
	//CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGRect statusFrame = [[UIApplication sharedApplication] statusBarFrame];
	
	// landscape
	if (isLandscape) {
		//CGFloat availWidth = appFrame.origin.y + appFrame.size.height;		// yeah, I know that this is strange...
		//CGFloat availHeight = appFrame.origin.x + appFrame.size.width - statusFrame.size.height;
		CGFloat availWidth = 1024.f;
#if USE_TWO_PART_ANIMATION
		CGFloat availHeight = 768.f - statusFrame.size.height;
#else
		CGFloat availHeight = 768.f - statusFrame.size.width;		// !!!
#endif
		CGFloat tabWidth = 0.f;
		
		if (usesFullLandscapeWidth) {
			containerView.frame = CGRectMake(0.f, 0.f, availWidth - tabWidth, availHeight);
		}
		else {
			CGFloat sideOffset = roundf((availWidth - 768.f) / 2);
			containerView.frame = CGRectMake(sideOffset, 0.f, 768.f, availHeight);
		}
	}
	
	// portrait
	else {
		CGFloat availWidth = 768.f;
#if USE_TWO_PART_ANIMATION
		CGFloat availHeight = 1024.f - statusFrame.size.width;		// !!!
#else
		CGFloat availHeight = 1024.f - statusFrame.size.height;
#endif
		CGFloat tabHeight = 0.f;
		
		containerView.frame = CGRectMake(0.f, 0.f, availWidth, availHeight - tabHeight);
	}
}
#pragma mark -



#pragma mark Rotation
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	if (usesFullLandscapeWidth) {
		containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		trackRotationAnimation = NO;
	}
	else {
		containerView.autoresizingMask = UIViewAutoresizingNone;
		wasLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
		trackRotationAnimation = YES;
	}
	
	// inform subview controllers
	[leftViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[rightViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[tabViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#if USE_TWO_PART_ANIMATION
- (void) willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (trackRotationAnimation) {
		isLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
		
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) != isLandscape) {
			[self layoutViews];
		}
	}
	
	//[leftViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//[rightViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//[tabViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (trackRotationAnimation) {
		
	}
	
	//[leftViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
	//[rightViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
	//[tabViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
}

#else

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (trackRotationAnimation) {
		isLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
		
		if (wasLandscape != isLandscape) {
			[self layoutViews];
		}
	}
	
	//[leftViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//[rightViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//[tabViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
#endif

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[leftViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[rightViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[tabViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
#pragma mark -



#pragma mark View Controller Handling
- (UIViewController *) leftViewController
{
	return leftViewController;
}
- (void) setLeftViewController:(UIViewController *)newController
{
	if (newController != leftViewController) {
		if (leftViewController) {
			if ([leftViewController isViewLoaded] && nil != [leftViewController.view superview]) {
				[leftViewController viewWillDisappear:NO];
				[leftViewController.view removeFromSuperview];
				[leftViewController viewDidDisappear:NO];
			}
			[leftViewController setParentController:nil];
		}
		
		[leftViewController release];
		leftViewController = [newController retain];
		
		if (nil != leftViewController) {
			[self addLeftView];
		}
	}
	
}

- (UIViewController *) rightViewController
{
	return rightViewController;
}
- (void) setRightViewController:(UIViewController *)newController
{
	if (newController != rightViewController) {
		if (rightViewController) {
			if ([rightViewController isViewLoaded] && nil != [rightViewController.view superview]) {
				[rightViewController viewWillDisappear:NO];
				[rightViewController.view removeFromSuperview];
				[rightViewController viewDidDisappear:NO];
			}
			[rightViewController setParentController:nil];
		}
		
		[rightViewController release];
		rightViewController = [newController retain];
		
		if ([self isViewLoaded] && nil != rightViewController) {
			[self addRightView];
		}
	}
	
}

- (UIView *) leftView
{
	if (nil == leftView) {
		[self loadView];
	}
	return leftView;
}
- (void) setLeftView:(UIView *)newView
{
	if (newView != leftView) {
		[leftView release];
		leftView = [newView retain];
	}
}

- (UIView *) rightView
{
	if (nil == rightView) {
		[self loadView];
	}
	return rightView;
}
- (void) setRightView:(UIView *)newView
{
	if (newView != rightView) {
		[rightView release];
		rightView = [newView retain];
	}
}
#pragma mark -



#pragma mark The Logo
- (UIImage *) logo
{
	return logo;
}
- (void) setLogo:(UIImage *)newLogo
{
	if (newLogo != logo) {
		[logo release];
		logo = [newLogo retain];
		
		if (logo) {
			if ([self isViewLoaded]) {
				self.logoView.image = logo;
				[self.view insertSubview:logoView atIndex:0];
			}
		}
	}
}

- (UIImageView *) logoView
{
	if (nil == logoView) {
		self.logoView = [[[UIImageView alloc] initWithImage:logo] autorelease];
		CGSize sz = [logoView frame].size;
		CGSize cs = [self.view bounds].size;
		logoView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		logoView.frame = CGRectMake(cs.width - sz.width - 5.f, cs.height - sz.height - 5.f, sz.width, sz.height);
	}
	return logoView;
}
- (void) setLogoView:(UIImageView *)newView
{
	if (newView != logoView) {
		[logoView release];
		logoView = [newView retain];
	}
}
#pragma mark -



#pragma mark Actions
- (void) addLeftView
{
	if (nil != leftViewController) {
		UIView *lView = leftViewController.view;
		lView.frame = leftView.bounds;
		
		[leftViewController viewWillAppear:NO];
		[leftView addSubview:lView];
		[leftViewController viewDidAppear:NO];
		
		// update navigation bar
		if (leftTitleBar.topItem != leftViewController.navigationItem) {
			[leftTitleBar pushNavigationItem:leftViewController.navigationItem animated:NO];
		}
	}
	else {
		DLog(@"No leftViewController");
	}
}

- (void) addRightView
{
	if (nil != rightViewController) {
		UIView *rView = rightViewController.view;
		rView.frame = rightView.bounds;
		
		[rightViewController viewWillAppear:NO];
		[rightView addSubview:rView];
		[rightViewController viewDidAppear:NO];
		
		// update navigation bar
		if (rightTitleBar.topItem != rightViewController.navigationItem) {
			[rightTitleBar pushNavigationItem:rightViewController.navigationItem animated:NO];
		}
	}
	else {
		DLog(@"No rightViewController");
	}
}
#pragma mark -



#pragma mark Utilities


@end

