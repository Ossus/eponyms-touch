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

@property (nonatomic, strong) UIColor *oldTextColor;
@property (nonatomic, readwrite, unsafe_unretained) PPHintView *hintViewDisplayed;

@end


@implementation PPHintableLabel


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = YES;
		self.adjustsFontSizeToFitWidth = YES;
		self.minimumFontSize = 12.f;
		
		self.readyColor = [UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f];
		self.activeColor = [UIColor colorWithRed:0.f green:0.4f blue:0.8f alpha:1.f];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.readyColor = [UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f];
		self.activeColor = [UIColor colorWithRed:0.f green:0.4f blue:0.8f alpha:1.f];
	}
	return self;
}



#pragma mark - KVC
- (void)setHintText:(NSString *)newHintText
{
	if (newHintText != _hintText) {
		_hintText = [newHintText copyWithZone:nil];
		
		if (nil != _hintText) {
			self.textColor = _readyColor;
			self.userInteractionEnabled = YES;
		}
		else {
			self.textColor = [UIColor blackColor];
			self.userInteractionEnabled = NO;
		}
	}
}



#pragma mark - Touch Handling
- (BOOL)canBecomeFirstResponder
{
	return (nil != _hintText);
}

- (BOOL)becomeFirstResponder
{
	if ([super becomeFirstResponder]) {
		if (nil != _hintViewDisplayed) {
			[_hintViewDisplayed hide];
			self.hintViewDisplayed = nil;
		}
		
		PPHintView *hintView = [PPHintView hintViewForView:self];
		hintView.textLabel.text = _hintText;
		[hintView show];
		return YES;
	}
	return NO;
}

- (BOOL)resignFirstResponder
{
	if (nil != _hintViewDisplayed) {
		[_hintViewDisplayed hide];
		self.hintViewDisplayed = nil;
	}
	
	if (nil != _oldTextColor) {
		self.textColor = _oldTextColor;
		self.oldTextColor = nil;
	}
	
	return [super resignFirstResponder];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (nil != _hintText) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];
		
		// if the touch up is inside ourself, show the hint
		if (CGRectContainsPoint(CGRectInset(self.bounds, -20.f, -5.f), location)) {
			[self becomeFirstResponder];
		}
	}
}



#pragma mark - Highlighting
- (void)hintView:(PPHintView *)hintView didDisplayAnimated:(BOOL)animated
{
	self.hintViewDisplayed = hintView;
	self.oldTextColor = self.textColor;
	self.textColor = _activeColor;
}

- (void)hintView:(PPHintView *)hintView didHideAnimated:(BOOL)animated
{
	self.hintViewDisplayed = nil;
	[self resignFirstResponder];
}


@end
