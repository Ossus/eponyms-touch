//
//  MCTextView.m
//  medcalc
//
//  Created by Pascal Pfiffner on 25.01.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//	Differently looking UITextView
//  

#import "MCTextView.h"


CGMutablePathRef createRoundedPathInRect(CGFloat borderRadius, CGRect rect);


@implementation MCTextView


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		myColorSpace = CGColorSpaceCreateDeviceRGB();
		self.opaque = NO;
		self.backgroundGradientType = 1;
		self.backgroundColor = nil;
		self.gradientBackgroundColor = [UIColor whiteColor];
		//self.contentInset = UIEdgeInsetsMake(-4.f, 0.f, 0.f, -4.f);		// seems to adjust self bounds -> weird drawing -> TODO: Find solution
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		myColorSpace = CGColorSpaceCreateDeviceRGB();
		self.opaque = NO;
		self.backgroundGradientType = 1;
		self.gradientBackgroundColor = self.backgroundColor;
		self.backgroundColor = nil;
	}
	return self;
}

- (void)dealloc
{
	CGColorSpaceRelease(myColorSpace);
	self.gradientBackgroundColor = nil;
}



#pragma mark - KVC
- (void)setBackgroundGradientType:(NSInteger)newType
{
	if (newType != _backgroundGradientType) {
		_backgroundGradientType = newType;
		
		if (nil != _gradientBackgroundColor) {
			UIColor *foo = _gradientBackgroundColor;
			self.gradientBackgroundColor = nil;
			self.gradientBackgroundColor = foo;
		}
	}
}

- (void)setGradientBackgroundColor:(UIColor *)newColor
{
	if (newColor != _gradientBackgroundColor) {
		_gradientBackgroundColor = newColor;
		
		if (backgroundGradient) {
			CGGradientRelease(backgroundGradient);
			backgroundGradient = NULL;
		}
		
		if (0 != _backgroundGradientType && nil != _gradientBackgroundColor) {
			CGColorRef cgColor = [newColor CGColor];
			size_t num_comp = CGColorGetNumberOfComponents(cgColor);
			const CGFloat *comp = CGColorGetComponents(cgColor);
			CGFloat topComponents[4];
			CGFloat bottomComponents[4];
			BOOL hasComponents = NO;
			
			// grayscale
			if (2 == num_comp) {
				CGFloat topWhite = (comp[0] + ((1.f - comp[0]) * 0.1f));
				CGFloat bottomWhite = (comp[0] - (comp[0] * 0.1f));
				topComponents[0] = topComponents[1] = topComponents[2] = topWhite;
				bottomComponents[0] = bottomComponents[1] = bottomComponents[2] = bottomWhite;
				topComponents[3] = comp[1];			// alpha
				bottomComponents[3] = comp[1];
				hasComponents = YES;
			}
			
			// rgba
			else if (4 == num_comp) {
				NSUInteger i;
				for (i = 0; i < 3; i++) {
					topComponents[i] = (comp[i] + ((1.f - comp[i]) * 0.1f));
					bottomComponents[i] = (comp[i] - (comp[i] * 0.1f));
				}
				topComponents[3] = comp[3];			// alpha
				bottomComponents[3] = comp[3];
				hasComponents = YES;
			}
			
			// save colors to the array
			if (hasComponents) {
				CGFloat components[8];
				NSUInteger i;
				
				if (1 == _backgroundGradientType) {
					for (i = 0; i < 8; i++) {
						components[i] = (i < 4) ? topComponents[i] : bottomComponents[i - 4];
					}
				}
				else {
					for (i = 0; i < 8; i++) {
						components[i] = (i < 4) ? bottomComponents[i] : topComponents[i - 4];
					}
				}
				
				CGFloat locations[2] = { 0.f, 1.f };
				backgroundGradient = CGGradientCreateWithColorComponents(myColorSpace, components, locations, 2);
			}
		}
	}
}



#pragma mark - Sizing
- (CGSize)sizeThatFits:(CGSize)size
{
	if ([self.text isEqualToString:@""]) {			// [self hasText] does not work??
		return size;
	}
	
	// calculate size needed by the text
	CGFloat textPadding = 8.f;
	CGSize maxSize = CGSizeMake(size.width - (2 * textPadding), size.height - (2 * textPadding));
	CGSize textSize = [self.text sizeWithFont:self.font constrainedToSize:maxSize];
	
	return CGSizeMake(textSize.width + (2 * textPadding), textSize.height + (2 * textPadding));
}

- (void)setFrame:(CGRect)newFrame
{
	if (!CGRectEqualToRect(newFrame, self.frame)) {
		[super setFrame:newFrame];
		
		// define the stretchable area
		[UIView setAnimationsEnabled:NO];
		
		CGSize selfSize = [self bounds].size;
		CGFloat borderWidth = 1.f;
		CGFloat borderRadius = 6.f;
		
		CGFloat top, bottom, left, right;
		top = bottom = left = right = fmaxf(borderWidth, borderRadius);
		CGFloat myLeft = left / selfSize.width;
		CGFloat myTop = top / selfSize.height;
		
		self.contentStretch = CGRectMake(myLeft, myTop, 1.f - right / selfSize.width - myLeft, 1.f - bottom / selfSize.height - myTop);
		
		[UIView setAnimationsEnabled:YES];
		
		[self setNeedsDisplay];
	}
}



#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGFloat borderRadius = 6.f;
	CGFloat borderWidth = 1.f;
	CGRect localRect = self.bounds;
	
	// draw the box border (fill the whole outline)
	CGContextSaveGState(context);
	
	CGMutablePathRef outlinePath = createRoundedPathInRect(borderRadius, localRect);
	CGContextAddPath(context, outlinePath);
	CGContextClip(context);
	
	// fill the clipped border area
	if (self.borderColor) {
		CGContextSetFillColorWithColor(context, [_borderColor CGColor]);
		CGContextFillRect(context, localRect);
	}
	else {
		CGFloat locations[2] = { 0.f, 1.f };
		CGFloat components[8] = {	0.2f, 0.25f, 0.4f, 0.5f,		// Top color
									0.4f, 0.45f, 0.55f, 0.2f };		// Bottom color
		CGGradientRef borderGradient = CGGradientCreateWithColorComponents(myColorSpace, components, locations, 2);
		
		CGPoint startPoint = CGPointMake(0.f, 0.f);
		CGPoint endPoint = CGPointMake(0.f, localRect.size.height);
		CGContextDrawLinearGradient(context, borderGradient, startPoint, endPoint, 0);
		CGGradientRelease(borderGradient);
	}
	CGContextRestoreGState(context);
	
	// draw the main box background
	if (nil != self.gradientBackgroundColor) {
		CGRect insetRect = CGRectInset(localRect, borderWidth, borderWidth);
		insetRect.origin.x = borderWidth;
		insetRect.origin.y = borderWidth;
		CGMutablePathRef boxPath = createRoundedPathInRect(borderRadius - borderWidth, insetRect);
		CGContextAddPath(context, boxPath);
		CGContextClip(context);
		
		if (backgroundGradient) {
			CGPoint startPoint = CGPointMake(0.f, 0.f);
			CGPoint endPoint = CGPointMake(0.f, localRect.size.height);
			CGContextDrawLinearGradient(context, backgroundGradient, startPoint, endPoint, 0);
		}
		else {
			CGContextSetFillColorWithColor(context, [_gradientBackgroundColor CGColor]);
			CGContextFillRect(context, localRect);
		}
		CGPathRelease(boxPath);
	}
	
	// draw box shadow
	if (self.editable) {
		CGMutablePathRef innerPath = createRoundedPathInRect(borderRadius - borderWidth, localRect);
		CGContextAddPath(context, innerPath);
		
		CGFloat shadowColorComponents[4] = { 0.f, 0.f, 0.f, 0.6f };
		CGFloat blackColorComponents[4] = { 0.f, 0.f, 0.f, 1.f };
		CGColorRef shadowColor = CGColorCreate(myColorSpace, shadowColorComponents);
		
		CGContextSetLineWidth(context, 2 * borderWidth);
		CGContextSetShadowWithColor(context, CGSizeMake(0.f, 1.f), 2.f, shadowColor);
		CGContextSetStrokeColor(context, blackColorComponents);
		CGContextStrokePath(context);
		CGColorRelease(shadowColor);
		CGPathRelease(innerPath);
	}
	
	// Clean up
	CGPathRelease(outlinePath);
	
	// call super to draw the text
	[super drawRect:rect];
}


CGMutablePathRef createRoundedPathInRect(CGFloat borderRadius, CGRect rect)
{
	CGPoint ro = rect.origin;
	CGSize rs = rect.size;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddArc(path, NULL, ro.x + borderRadius,				ro.y + borderRadius,				borderRadius, 1.f * M_PI, 1.5f * M_PI, 0);
	CGPathAddArc(path, NULL, ro.x + rs.width - borderRadius,	ro.y + borderRadius,				borderRadius, 1.5f * M_PI, 0.f, 0);
	CGPathAddArc(path, NULL, ro.x + rs.width - borderRadius,	ro.y + rs.height - borderRadius,	borderRadius, 0.f, 0.5f * M_PI, 0);
	CGPathAddArc(path, NULL, ro.x + borderRadius,				ro.y + rs.height - borderRadius,	borderRadius, 0.5f * M_PI, 1.f * M_PI, 0);
	CGPathCloseSubpath(path);
	
	return path;			// don't forget to CGPathRelease() !
}


@end
