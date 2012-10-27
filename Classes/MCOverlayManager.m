//
//  MCOverlayManager.m
//  medcalc
//
//  Created by Pascal Pfiffner on 12/16/10.
//  Copyright 2010 MedCalc. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//	

#import "MCOverlayManager.h"
#import <QuartzCore/QuartzCore.h>


@interface MCOverlayManager ()

@property (nonatomic, assign) CGPoint presentCenter;
@property (nonatomic, readwrite, strong) UIView *referenceView;
@property (nonatomic, readwrite, strong) UIView *presentedView;
@property (nonatomic, strong) UIView *willPresentInView;
@property (nonatomic, strong) NSTimer *pollTimer;

- (void)adjustFrame;
- (void)positionViewAnimated:(BOOL)animated;
- (UIView *)overlayViewFor:(UIView *)refView;

- (void)doPoll;

@end


@implementation MCOverlayManager

static MCOverlayManager *overlayManager = nil;

@synthesize delegate;
@synthesize presentCenter, referenceView, presentedView, willPresentInView;
@synthesize inAnimation, outAnimation;
@synthesize selectReference;
@synthesize alignOnScreen;
@synthesize pollPosition, pollTimer;


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[pollTimer invalidate];
	
	@synchronized(self) {
		if (self == overlayManager) {
			overlayManager = nil;
		}
	}
}


+ (MCOverlayManager *)sharedManager
{
	@synchronized(self) {
		if (!overlayManager) {
			overlayManager = [[MCOverlayManager alloc] initWithFrame:CGRectMake(0.f, 0.f, 100.f, 100.f)];
		}
		return overlayManager;
	}
}

/**
 *	Returns YES if the shared manager is displaying an overlay in refView or it's child views
 */
+ (BOOL)overlayShownInDescendantOfView:(UIView *)refView
{
	@synchronized(self) {
		UIView *superview = [overlayManager superview];
		if (superview) {
			return [superview isDescendantOfView:refView];
		}
	}
	return NO;
}

- (id)initWithFrame:(CGRect)aFrame
{
	if ((self = [super initWithFrame:aFrame])) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		inAnimation = MCAnimationTypeZoomFromToCenter;
		outAnimation = MCAnimationTypeZoomFromToCenter;
		selectReference = YES;
		alignOnScreen = YES;
		
		[self addTarget:self action:@selector(hideOverlay:) forControlEvents:UIControlEventTouchUpInside];
		
		// subscribe to rotation notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(deviceDidRotate:)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];
	}
	return self;
}



#pragma mark - Overlay
- (UIView *)overlayViewFor:(UIView *)refView
{
	UIView *child = refView;
	UIView *parent = nil;
	UIView *attachToView = nil;
	
	while ((parent = [child superview])) {
		NSString *parentClass = NSStringFromClass([parent class]);
		if ([parentClass isEqualToString:@"UILayoutContainerView"]) {		// iPad popover
			attachToView = parent;
			break;
		}
		else if ([UIWindow class] == [parent class]) {						// first UIWindow subview
			attachToView = child;
			break;
		}
		child = parent;
	}
	
	if (!attachToView) {
		attachToView = child;
	}
	//DLog(@"-- USING --\n%@", attachToView);
	
	return attachToView;
}


- (void)overlay:(UIView *)aView withCenter:(CGPoint)atOrigin inView:(UIView *)refView
{
	self.presentedView = aView;
	self.presentCenter = atOrigin;
	self.referenceView = refView;
	
	// claim focus
	[referenceView becomeFirstResponder];
	if (selectReference && [referenceView respondsToSelector:@selector(setSelected:)]) {
		[(UIControl *)referenceView setSelected:YES];
	}
	
	// find the view to attach to
	if (![self superview]) {
		self.willPresentInView = [self overlayViewFor:refView];
		[willPresentInView addSubview:self];
	}
	
	// layout
	[self adjustFrame];
	[self positionViewAnimated:YES];
	
	// start polling
	if (pollPosition) {
		self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(doPoll) userInfo:nil repeats:YES];
	}
}

- (CGSize)overlaySizeForView:(UIView *)refView
{
	if (![self superview]) {
		self.willPresentInView = [self overlayViewFor:refView];
		[willPresentInView addSubview:self];
		[self adjustFrame];
	}
	
	return [self bounds].size;
}


- (void)adjustFrame
{
	// subtract status bar rect from our possible rect
	CGRect attachFrame = [self superview].bounds;
	CGRect statusFrame = [[self superview] convertRect:[UIApplication sharedApplication].statusBarFrame fromView:self.window];
	if (CGRectIntersectsRect(statusFrame, attachFrame)) {
		if (statusFrame.origin.y < 1.f) {
			attachFrame.origin.y = statusFrame.size.height;
		}
		attachFrame.size.height -= statusFrame.size.height;
	}
	
	// adjust ourselves
	self.frame = attachFrame;
	[[self superview] bringSubviewToFront:self];
}


- (void)positionViewAnimated:(BOOL)animated
{
	if (!presentedView || !referenceView) {
		return;
	}
	
	// check whether we're in bounds
	CGPoint atOrigin = [self convertPoint:presentCenter fromView:referenceView];
	lastCenter = atOrigin;
	
	if (alignOnScreen) {
		CGSize fitSize = [presentedView bounds].size;
		CGSize attachSize = [[self superview] bounds].size;
		
		if ((atOrigin.x - (fitSize.width / 2)) < 0.f) {
			atOrigin.x = roundf(fitSize.width / 2);
		}
		else if ((atOrigin.x + (fitSize.width / 2)) > attachSize.width) {
			atOrigin.x = attachSize.width - roundf(fitSize.width / 2);
		}
		
		if ((atOrigin.y - (fitSize.height / 2)) < 0.f) {
			atOrigin.y = roundf(fitSize.height / 2);
		}
		else if ((atOrigin.y + (fitSize.height / 2)) > attachSize.height) {
			atOrigin.y = attachSize.height - roundf(fitSize.height / 2);
		}
	}
	
	// not yet there - position correctly
	if (![presentedView superview]) {
		presentedView.center = atOrigin;
		if (MCAnimationTypeFadeInOut == inAnimation) {
			presentedView.layer.opacity = 0.f;
		}
		else if (MCAnimationTypeZoomFromToCenter == inAnimation) {
			presentedView.layer.opacity = 0.2f;
			presentedView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
		}
		[self addSubview:presentedView];
	}
	
	// animate changes
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		//[UIView setAnimationDuration:0.1f];
	}
	
	presentedView.center = atOrigin;
	presentedView.layer.opacity = 1.f;
	presentedView.transform = CGAffineTransformIdentity;
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)moveOverlayTo:(CGPoint)newCenter animated:(BOOL)animated
{
	self.presentCenter = newCenter;
	[self positionViewAnimated:animated];
}



#pragma mark - Remove from Overlay
- (void)hideOverlayAnimated:(BOOL)animated
{
	if (pollTimer) {
		[pollTimer invalidate];
		self.pollTimer = nil;
	}
	
	if ([self superview]) {
		
		// release focus
		[referenceView resignFirstResponder];
		if (selectReference && [referenceView respondsToSelector:@selector(setSelected:)]) {
			[(UIControl *)referenceView setSelected:NO];
		}
		
		// inform delegate
		if (delegate && [delegate respondsToSelector:@selector(willDismissOverlay:)]) {
			[delegate willDismissOverlay:self];
		}
		
		// remove
		if (animated) {
			[UIView animateWithDuration:0.2
							 animations:^{
								 if (MCAnimationTypeFadeInOut == inAnimation) {
									 presentedView.layer.opacity = 0.f;
								 }
								 else if (MCAnimationTypeZoomFromToCenter == inAnimation) {
									 presentedView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
									 presentedView.layer.opacity = 0.2f;
								 }
							 }
							 completion:^(BOOL finished) {
								 [self removeFromSuperview];
								 self.layer.opacity = 1.f;
								 self.delegate = nil;
								 
								 [presentedView removeFromSuperview];
								 presentedView.layer.opacity = 1.f;
								 self.presentedView = nil;
							 }];
		}
		else {
			[self removeFromSuperview];
			self.layer.opacity = 1.f;
			self.delegate = nil;
			
			[presentedView removeFromSuperview];
			presentedView.layer.opacity = 1.f;
			self.presentedView = nil;
		}
	}
}

- (void)hideOverlay:(id)sender
{
	[self hideOverlayAnimated:(nil != sender)];
}

- (void)hideOverlayAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
	[self performSelector:@selector(hideOverlay:) withObject:(animated ? self : nil) afterDelay:delay];
}



#pragma mark - Rotation Handling
- (void)deviceDidRotate:(NSNotification *)aNotification
{
	if (![delegate respondsToSelector:@selector(overlayShouldReposition:)]
		|| [delegate overlayShouldReposition:self]) {
		if ([delegate respondsToSelector:@selector(overlayWillMoveToNewPosition:)]) {
			[delegate overlayWillMoveToNewPosition:self];
		}
		
		[self positionViewAnimated:NO];
		
		if ([delegate respondsToSelector:@selector(overlayDidMoveToNewPosition:)]) {
			[delegate overlayDidMoveToNewPosition:self];
		}
	}
}



#pragma mark - Position Polling
- (void)doPoll
{
	if (referenceView) {
		CGPoint atOrigin = [self convertPoint:presentCenter fromView:referenceView];
		
		// new position!
		if (!CGPointEqualToPoint(lastCenter, atOrigin)) {
			if (![delegate respondsToSelector:@selector(overlayShouldReposition:)]
				|| [delegate overlayShouldReposition:self]) {
				if ([delegate respondsToSelector:@selector(overlayWillMoveToNewPosition:)]) {
					[delegate overlayWillMoveToNewPosition:self];
				}
				
				[self positionViewAnimated:YES];
				
				if ([delegate respondsToSelector:@selector(overlayDidMoveToNewPosition:)]) {
					[delegate overlayDidMoveToNewPosition:self];
				}
			}
		}
	 }
}


@end
