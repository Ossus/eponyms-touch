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


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didRotate:)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];
	}
	return self;
}
#pragma mark -



#pragma mark Actions
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[hint hide];
}

- (void) didRotate:(NSNotification *)aNotification
{
	[hint hide];
}


@end
