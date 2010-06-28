//
//  UIView+shadowBug.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 20.06.10.
//  Copyright 2010 Pascal Pfiffner. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UIView category to correct the y-direction change that happened for Quartz shadows between iOS 3.1 and iOS 3.2
// 

#import "UIView+shadowBug.h"


@implementation UIView (shadowBug)

+ (NSInteger) shadowVerticalMultiplier
{
	static NSInteger shadowVerticalMultiplier = 0;
	if (0 == shadowVerticalMultiplier) {
		CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
		shadowVerticalMultiplier = (systemVersion < 3.2f) ? -1 : 1;
	}
	
	return shadowVerticalMultiplier;
}


@end
