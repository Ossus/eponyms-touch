//
//  PPHintableLabel.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 25.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//

#import "PPHintableLabel.h"
#import "PPHintView.h"


@interface PPHintableLabel ()

@property (nonatomic, retain) UIColor *oldTextColor;
@property (nonatomic, readwrite, assign) PPHintView *hintViewDisplayed;

@end


@implementation PPHintableLabel

@dynamic hintText;
@synthesize readyColor;
@synthesize activeColor;
@synthesize oldTextColor;
@synthesize hintViewDisplayed;


- (void) dealloc
{
	self.hintText = nil;
	self.readyColor = nil;
	self.activeColor = nil;
	self.oldTextColor = nil;
	
    [super dealloc];
}

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = YES;
		self.adjustsFontSizeToFitWidth = YES;
		self.minimumFontSize = 12.f;
		
		self.readyColor = [UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f];
		self.activeColor = [UIColor colorWithRed:0.f green:0.4f blue:0.8f alpha:1.f];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		self.readyColor = [UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f];
		self.activeColor = [UIColor colorWithRed:0.f green:0.4f blue:0.8f alpha:1.f];
	}
	return self;
}
#pragma mark -



#pragma mark KVC
- (NSString *) hintText
{
	return hintText;
}
- (void) setHintText:(NSString *)newHintText
{
	if (newHintText != hintText) {
		[hintText release];
		hintText = [newHintText copyWithZone:[self zone]];
		
		if (nil != hintText) {
			self.textColor = readyColor;
			self.userInteractionEnabled = YES;
		}
		else {
			self.textColor = [UIColor blackColor];
			self.userInteractionEnabled = NO;
		}
	}
}
#pragma mark -



#pragma mark Touch Handling
- (BOOL) canBecomeFirstResponder
{
	return (nil != hintText);
}

- (BOOL) becomeFirstResponder
{
	if ([super becomeFirstResponder]) {
		if (nil != hintViewDisplayed) {
			[hintViewDisplayed hide];
			self.hintViewDisplayed = nil;
		}
		
		PPHintView *hintView = [PPHintView hintViewForView:self];
		hintView.textLabel.text = hintText;
		[hintView show];
		return YES;
	}
	return NO;
}

- (BOOL) resignFirstResponder
{
	if (nil != hintViewDisplayed) {
		[hintViewDisplayed hide];
		self.hintViewDisplayed = nil;
	}
	
	if (nil != oldTextColor) {
		self.textColor = oldTextColor;
		self.oldTextColor = nil;
	}
	
	return [super resignFirstResponder];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (nil != hintText) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];
		
		// if the touch up is inside ourself, show the hint
		if (CGRectContainsPoint(CGRectInset(self.bounds, -20.f, -5.f), location)) {
			[self becomeFirstResponder];
		}
	}
}
#pragma mark -



#pragma mark Highlighting
- (void) hintView:(PPHintView *)hintView didDisplayAnimated:(BOOL)animated
{
	self.hintViewDisplayed = hintView;
	self.oldTextColor = self.textColor;
	self.textColor = activeColor;
}

- (void) hintView:(PPHintView *)hintView didHideAnimated:(BOOL)animated
{
	self.hintViewDisplayed = nil;
	[self resignFirstResponder];
}


@end
