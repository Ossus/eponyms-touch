//
//  PPHintViewContainer.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 20.10.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import "PPHintViewContainer.h"
#import "PPHintView.h"


@implementation PPHintViewContainer

@synthesize hint;


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = YES;
	}
	return self;
}


- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[hint hide];
}

@end
