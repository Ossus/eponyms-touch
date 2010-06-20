//
//  MCViewAnimations.m
//  medcalc
//
//  Created by Pascal Pfiffner on 28.03.10.
//	Copyright 2010 MedCalc. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import "MCViewAnimations.h"
#import <QuartzCore/QuartzCore.h>


@interface UIView (MCViewAnimationsPrivate)

- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end


@implementation UIView (MCViewAnimations)

static NSString *removeAnimID = @"removeFromSuperviewAnimated";


#pragma mark View Hierarchy
- (void) addSubviewAnimated:(UIView *)view
{
	view.layer.opacity = 0.f;
	[self addSubview:view];
	
	// animate
	[UIView beginAnimations:nil context:nil];
	view.layer.opacity = 1.f;
	[UIView commitAnimations];
}


- (void) removeFromSuperviewAnimated
{
	if (nil != [self superview] && nil == [self.layer animationForKey:removeAnimID]) {
		CAKeyframeAnimation *fadeAnim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
		fadeAnim.delegate = self;
		fadeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		fadeAnim.calculationMode = kCAAnimationLinear;
		fadeAnim.removedOnCompletion = NO;
		
		fadeAnim.values = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:0], nil];
		
		[self.layer addAnimation:fadeAnim forKey:removeAnimID];
	}
}

- (void) animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	if (theAnimation == [self.layer animationForKey:removeAnimID]) {
		[self removeFromSuperview];
		[self.layer removeAllAnimations];
	}
}
#pragma mark -



#pragma mark Animations
- (void) curvedMoveFromCenter:(CGPoint)startCenter toCenter:(CGPoint)targetCenter withDelegate:(id)animDelegate forKey:(NSString *)animKey
{
	CAKeyframeAnimation *curveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	curveAnimation.delegate = animDelegate;
	curveAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	curveAnimation.calculationMode = kCAAnimationPaced;
	curveAnimation.fillMode = kCAFillModeForwards;
	curveAnimation.removedOnCompletion = NO;
	curveAnimation.duration = 0.4;
	curveAnimation.repeatCount = 0;
	
	// create the path
	CGFloat middleX = fminf(targetCenter.x, startCenter.x) + fabsf(targetCenter.x - startCenter.x) * 0.5f;
	CGFloat middleY = fminf(targetCenter.y, startCenter.y) + fabsf(targetCenter.y - startCenter.y) * 0.5f;
	CGMutablePathRef curvedPath = CGPathCreateMutable();
	CGPathMoveToPoint(curvedPath, NULL, startCenter.x, startCenter.y);
	CGPathAddCurveToPoint(curvedPath, NULL,
						  middleX, startCenter.y,
						  targetCenter.x, middleY,
						  targetCenter.x, targetCenter.y);
	
	// use this path for the animation
	curveAnimation.path = curvedPath;
	CGPathRelease(curvedPath);
	
	// animate!
	[self.layer addAnimation:curveAnimation forKey:animKey];
}


- (void) bubbleViewWithDelegate:(id)animDelegate forKey:(NSString *)animKey
{
	CAKeyframeAnimation *bubbleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.height"];
	bubbleAnimation.delegate = animDelegate;
	bubbleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	bubbleAnimation.calculationMode = kCAAnimationLinear;
	bubbleAnimation.removedOnCompletion = YES;
	bubbleAnimation.duration = 0.2;
	
	CGFloat viewHeight = [self bounds].size.height;
	NSNumber *origHeight = [NSNumber numberWithFloat:viewHeight];
	NSNumber *bubbleHeight = [NSNumber numberWithFloat:1.5f * viewHeight];
	
	bubbleAnimation.values = [NSArray arrayWithObjects:origHeight, bubbleHeight, origHeight, nil];
	
	// animate!
	[self.layer addAnimation:bubbleAnimation forKey:animKey];
}


@end
