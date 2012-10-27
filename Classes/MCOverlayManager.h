//
//  MCOverlayManager.h
//  medcalc
//
//  Created by Pascal Pfiffner on 12/16/10.
//  Copyright 2010 MedCalc. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import <UIKit/UIKit.h>

typedef enum {
	MCAnimationTypeFadeInOut = 1,
	MCAnimationTypeZoomFromToCenter
} MCAnimationType;

@class MCOverlayManager;

@protocol MCOverlayManagerDelegate <NSObject>

@optional
- (void) willDismissOverlay:(MCOverlayManager *)overlay;
- (BOOL) overlayShouldReposition:(MCOverlayManager *)overlay;
- (void) overlayWillMoveToNewPosition:(MCOverlayManager *)overlay;
- (void) overlayDidMoveToNewPosition:(MCOverlayManager *)overlay;

@end



/**
 *	An object which handles views which modally overlay the current view.
 *	Currently, this is an autoreleasing singleton, but you may create your own instances (not tested)
 */
@interface MCOverlayManager : UIControl {
	id <MCOverlayManagerDelegate> __unsafe_unretained delegate;
	CGPoint presentCenter;
	
	@private
	CGPoint lastCenter;								///< center converted to local coordinates without bounds checking
	NSTimer *pollTimer;
}

@property (nonatomic, unsafe_unretained) id <MCOverlayManagerDelegate> delegate;
@property (nonatomic, readonly, strong) UIView *willPresentInView;						///< set by -overlaySize, and the actual overlay calls
@property (nonatomic, readonly, strong) UIView *referenceView;
@property (nonatomic, readonly, strong) UIView *presentedView;
@property (nonatomic, assign) MCAnimationType inAnimation;								///< default: MCAnimationTypeZoomFromToCenter
@property (nonatomic, assign) MCAnimationType outAnimation;								///< default: MCAnimationTypeZoomFromToCenter
@property (nonatomic, assign) BOOL selectReference;										///< YES by default if referenceView responds to setSelected:
@property (nonatomic, assign) BOOL alignOnScreen;										///< YES by default. If NO does not check whether the view is visible
@property (nonatomic, assign) BOOL pollPosition;										///< NO by default. If YES checks the view's position 4 times per second to react to changes

+ (MCOverlayManager *)sharedManager;
+ (BOOL)overlayShownInDescendantOfView:(UIView *)refView;
- (void)overlay:(UIView *)aView withCenter:(CGPoint)atOrigin inView:(UIView *)refView;		// atOrigin is relative to refView
- (CGSize)overlaySizeForView:(UIView *)refView;	// you can call this before overlaying to get the maximum possible overlay size
- (void)moveOverlayTo:(CGPoint)newCenter animated:(BOOL)animated;			// assumes newCenter is in the same coordinate system as referenceView

- (void)hideOverlay:(id)sender;
- (void)hideOverlayAnimated:(BOOL)animated;
- (void)hideOverlayAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;


@end
