//
//  MCTextView.h
//  medcalc
//
//  Created by Pascal Pfiffner on 25.01.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//	Differently looking UITextView
//  

#import <UIKit/UIKit.h>


@interface MCTextView : UITextView {
	CGColorSpaceRef myColorSpace;
	CGGradientRef backgroundGradient;
}

@property (nonatomic, strong) UIColor *borderColor;

@property (nonatomic, assign) NSInteger backgroundGradientType;				// -1: dark to bright; 0: none; 1: bright to dark (default)
@property (nonatomic, strong) UIColor *gradientBackgroundColor;


@end
