//
//  PPHintView.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 18.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//  
//  A custom view that displays text pointing at some element
//	Deduced from MedCalc's MCPopupView
// 

#import <UIKit/UIKit.h>
@class PPHintViewContainer;


@interface PPHintView : UIView {
	PPHintViewContainer *containerView;
	
	UIView *forElement;
	CGRect elementFrame;				// element frame as if it was on our containerView
	CGPoint elementCenter;				// the center of the element
	
	UILabel *titleLabel;
	UILabel *textLabel;
	
	NSInteger position;					// 0 = top, 1 = left, 2 = bottom, 3 = right
	CGRect boxRect;						// the rect of the actual box
	
	CGColorRef cgBackgroundColor;
	CGColorRef cgBorderColor;
	CGColorRef cgBoxShadowColor;
	CGColorRef cgBlackColor;
	CGGradientRef cgGlossGradient;
}

@property (nonatomic, readonly, retain) PPHintViewContainer *containerView;
@property (nonatomic, assign) UIView *forElement;

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *textLabel;

+ (PPHintView *) hintViewForView:(UIView *)forView;

- (void) show;
- (void) hide;
- (CGRect) insideRect;


@end
