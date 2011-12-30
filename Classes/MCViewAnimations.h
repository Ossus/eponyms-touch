//
//  MCViewAnimations.h
//  medcalc
//
//  Created by Pascal Pfiffner on 28.03.10.
//	Copyright 2010 MedCalc. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import <UIKit/UIKit.h>


@interface UIView (MCViewAnimations)

- (void) addSubviewAnimated:(UIView *)view;
- (void) removeFromSuperviewAnimated;

- (void) curvedMoveFromCenter:(CGPoint)startCenter toCenter:(CGPoint)targetCenter withDelegate:(id)animDelegate forKey:(NSString *)animKey;
- (void) bubbleViewWithDelegate:(id)animDelegate forKey:(NSString *)animKey;


@end
