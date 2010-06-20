//
//  PPHintViewContainer.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 20.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
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
