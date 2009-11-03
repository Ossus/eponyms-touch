//
//  PPHintableLabel.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 25.10.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import "PPHintableLabel.h"
#import "PPHintView.h"


@interface PPHintableLabel ()

@property (nonatomic, retain) UIColor *oldTextColor;
@property (nonatomic, readwrite, assign) PPHintView *hintViewDisplayed;

@end


@implementation PPHintableLabel

@synthesize hintText;
@synthesize oldTextColor;
@synthesize hintViewDisplayed;


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
		self.adjustsFontSizeToFitWidth = YES;
		self.minimumFontSize = 12.0;
    }
    return self;
}

- (void) dealloc
{
	self.hintText = nil;
	self.oldTextColor = nil;
	
    [super dealloc];
}
#pragma mark -



#pragma mark Touch Handling
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (nil != hintText) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];
		
		// if the touch up is inside ourself, show the hint
		if (CGRectContainsPoint(CGRectInset(self.bounds, -20.0, -5.0), location)) {
			PPHintView *hintView = [PPHintView hintViewForView:self];
			hintView.textLabel.text = hintText;
			[hintView show];
		}
	}
}
#pragma mark -



#pragma mark Highlighting
- (void) hintView:(PPHintView *)hintView didDisplayAnimated:(BOOL)animated
{
	self.hintViewDisplayed = hintView;
	self.oldTextColor = self.textColor;
	self.textColor = [UIColor colorWithRed:0.0 green:0.25 blue:0.5 alpha:1.0];
}

- (void) hintView:(PPHintView *)hintView didHideAnimated:(BOOL)animated
{
	self.hintViewDisplayed = nil;
	if (nil != oldTextColor) {
		self.textColor = oldTextColor;
		self.oldTextColor = nil;
	}
}


@end
