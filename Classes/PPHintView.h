//
//  PPHintView.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 18.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "MCOverlayManager.h"

typedef void (^PPHintViewDismissalBlock)(void);

/**
 *	A custom view that displays text pointing at some element
 *	Deduced from MedCalc's MCPopupView
 */
@interface PPHintView : UIView <MCOverlayManagerDelegate> {
	MCOverlayManager *overlayManager;
	
	UILabel *titleLabel;
	UILabel *textLabel;
	UIFont *originalTitleFont;
	UIFont *originalTextFont;
	
	BOOL resignFirstResponderUponHide;			///< YES by default. If NO the view pointed to will keep first responder status upon hiding the hint.
	PPHintViewDismissalBlock dismissBlock;		///< Block to be executed when the hint hides
	
	@private
	NSInteger position;							///< 0 = top, 1 = left, 2 = bottom, 3 = right
	CGRect boxRect;								///< the rect of the actual box inside our bounds
	UIView *textContainer;						///< contains the text labels
	UIColor *myBackgroundColor;					///< cache for backgroundColor, which we'll leave untouched
	
	CGColorRef cgBackgroundColor;
	CGColorRef cgBorderColor;
	CGColorRef cgBoxShadowColor;
	CGColorRef cgBlackColor;
	CGGradientRef cgGlossGradient;
}

@property (nonatomic, readonly, strong) MCOverlayManager *overlayManager;
@property (nonatomic, unsafe_unretained) UIView *forElement;
@property (nonatomic, assign) BOOL resignFirstResponderUponHide;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, copy) PPHintViewDismissalBlock dismissBlock;

+ (PPHintView *)hintViewForView:(UIView *)forView;

- (void)show;
- (void)hide;
- (CGRect)insideRect;


@end
