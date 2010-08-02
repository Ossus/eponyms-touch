//
//  PPHintView.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 18.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//  
//  A custom view that displays text pointing at some element
//	Deduced from MedCalc's MCPopupView
//

#import "PPHintView.h"
#import "PPHintViewContainer.h"
#import "PPHintableLabel.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+shadowBug.h"

#define kPopupBoxPadding 10.0			// min distance to screen edges
#define kPopupElementDistance 10.0		// distance to the referring element
#define kPopupMarginForShadow 30.0		// the frame will be this much bigger
#define kPopupShadowOffset 6.0			// shadow offset downwards
#define kPopupShadowBlurRadius 18.0		// shadow blur radius
#define kPopupTextXPadding 12.0
#define kPopupTextYPadding 8.0
#define kPopupTitleLabelHeight 20.0


@interface PPHintView ()

@property (nonatomic, readwrite, retain) PPHintViewContainer *containerView;

- (void) setupForView:(UIView *)forView;
- (void) hideAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

- (void) initCGObjects;
- (void) releaseCGObjects;
CGMutablePathRef createOutlinePath(NSInteger pPosition, CGRect pRect, CGPoint elemCenter, CGFloat borderWidth, CGFloat borderRadius);
CGMutablePathRef createGlossPath(CGRect pRect, CGFloat glossHeight);

@end
#pragma mark -


@implementation PPHintView

@synthesize forElement;
@dynamic containerView;
@dynamic titleLabel;
@dynamic textLabel;


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
		//self.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:1.f alpha:0.3f];
		self.opaque = NO;
		self.userInteractionEnabled = YES;
		
		// create the colors
		[self initCGObjects];
    }
	
    return self;
}

+ (PPHintView *) hintViewForView:(UIView *)forView;
{
	CGRect appRect = [[UIScreen mainScreen] bounds];
	PPHintView *view = [[self alloc] initWithFrame:appRect];
	[view setupForView:forView];
	
	return [view autorelease];
}

- (void) setupForView:(UIView *)forView
{
	self.forElement = forView;
}

- (void) dealloc
{
	self.forElement = nil;
	self.containerView = nil;
	self.titleLabel = nil;
	self.textLabel = nil;
	
	[self releaseCGObjects];
	
    [super dealloc];
}
#pragma mark -



#pragma mark KVC
- (PPHintViewContainer *) containerView
{
	if (nil == containerView) {
		CGRect appRect = [[UIScreen mainScreen] bounds];
		self.containerView = [[[PPHintViewContainer alloc] initWithFrame:appRect] autorelease];
		//containerView.layer.delegate = self;
		containerView.hint = self;
	}
	
	return containerView;
}
- (void) setContainerView:(PPHintViewContainer *)newContainer
{
	if (newContainer != containerView) {
		[containerView release];
		containerView = [newContainer retain];
	}
}

- (UILabel *) titleLabel
{
	if (nil == titleLabel) {
		CGRect frame = CGRectInset(self.bounds, kPopupMarginForShadow + kPopupTextXPadding, kPopupMarginForShadow + kPopupTextYPadding);
		frame.size.height = kPopupTitleLabelHeight;
		
		self.titleLabel = [[UILabel alloc] initWithFrame:frame];
		titleLabel.opaque = NO;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textColor = [UIColor whiteColor];
		titleLabel.font = [UIFont boldSystemFontOfSize:17.f];
		titleLabel.adjustsFontSizeToFitWidth = YES;
		titleLabel.shadowColor = [UIColor colorWithWhite:0.f alpha:0.9f];
		titleLabel.shadowOffset = CGSizeMake(0.f, -1.f);
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[self addSubview:[titleLabel autorelease]];
	}
	
	return titleLabel;
}
- (void) setTitleLabel:(UILabel *)newTitleLabel
{
	if (newTitleLabel != titleLabel) {
		if (nil != [titleLabel superview]) {
			[titleLabel removeFromSuperview];
		}
		[titleLabel release];
		titleLabel = [newTitleLabel retain];
	}
}

- (UILabel *) textLabel
{
	if (nil == textLabel) {
		CGRect frame = CGRectInset(self.bounds, kPopupMarginForShadow + kPopupTextXPadding, kPopupMarginForShadow + kPopupTextYPadding);
		CGFloat topPadding = titleLabel ? (kPopupTitleLabelHeight + kPopupTextYPadding / 2) : 0.f;
		frame.origin.y += topPadding;
		frame.size.height -= topPadding;
		
		self.textLabel = [[UILabel alloc] initWithFrame:frame];
		textLabel.opaque = NO;
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.font = [UIFont systemFontOfSize:15.f];
		textLabel.shadowColor = [UIColor colorWithWhite:0.f alpha:0.9f];
		textLabel.shadowOffset = CGSizeMake(0.f, -1.f);
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		textLabel.numberOfLines = 100;
		
		[self addSubview:[textLabel autorelease]];
	}
	
	return textLabel;
}
- (void) setTextLabel:(UILabel *)newTextLabel
{
	if (newTextLabel != textLabel) {
		if (nil != [textLabel superview]) {
			[textLabel removeFromSuperview];
		}
		[textLabel release];
		textLabel = [newTextLabel retain];
	}
}
#pragma mark -



#pragma mark GUI
- (void) show
{
	if (nil == forElement) {
		NSLog(@"PPHintView: Cannot show without an element to point to");
		return;
	}
	
	// we don't want to display something under the status bar
	BOOL is_landscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
	CGSize sbs = [UIApplication sharedApplication].statusBarFrame.size;
	CGFloat statusBarHeight = is_landscape ? sbs.width : sbs.height;
	
	// find the view we want to attach to
	CGPoint origin = CGPointZero;				// this will be the center of the popup
	UIView *child = forElement;
	UIView *parent = nil;
	UIView *attachToView = nil;
	
	while (parent = [child superview]) {
		NSString *parentClass = NSStringFromClass([parent class]);
		if ([parentClass isEqualToString:@"UILayoutContainerView"]) {
			attachToView = parent;
			break;
		}
		else if ([UIWindow class] == [parent class]) {
			attachToView = child;
			break;
		}
		child = parent;
	}
	if (!attachToView) {
		attachToView = child;
	}
	//DLog(@"-- USING --\n%@", attachToView);
	CGSize attachSize = [attachToView bounds].size;
	self.containerView.frame = CGRectMake(0.f, 0.f, attachSize.width, attachSize.height);
	
	elementFrame = [attachToView convertRect:forElement.frame fromView:[forElement superview]];
	CGPoint refElementCenter = [attachToView convertPoint:forElement.center fromView:[forElement superview]];
	
	// calculate needed dimensions based on the titleLabel (width) and textView (height)
	CGFloat boxWidth = 0.f;
	CGFloat boxHeight = 0.f;
	if (nil != titleLabel) {
		CGSize labelSize = [titleLabel.text sizeWithFont:titleLabel.font];
		boxWidth = fminf(labelSize.width + 2 * kPopupTextXPadding, attachSize.width - 2 * kPopupBoxPadding);
		boxHeight = kPopupTextYPadding + 20.f + kPopupTextYPadding;
	}
	if (nil != textLabel) {
		BOOL useWidth = NO;
		if (0.f == boxWidth) {
			useWidth = YES;
			boxWidth = attachSize.width - 2 * kPopupBoxPadding;
		}
		CGSize maxSize = CGSizeMake(boxWidth - 2 * kPopupTextXPadding, 600.f);
		CGSize textSize = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:maxSize];
		CGFloat widthHeightRatio = textSize.width / textSize.height;
		
		//especially on the iPad, we don't want to have a view the whole screen wide but only one or two lines of text
		if (widthHeightRatio > 4.f && textSize.width > 320.f) {
			maxSize.width = fmaxf(320.f - 2 * kPopupBoxPadding, textSize.width / (widthHeightRatio / 3));		// 3 is approx. the target ratio
			textSize = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:maxSize];
		}
		
		// set box height according to needed size
		boxHeight = ([textLabel frame].origin.y - kPopupMarginForShadow) + textSize.height + kPopupTextYPadding;
		if (useWidth) {
			boxWidth = textSize.width + 2 * kPopupTextXPadding;
		}
	}
	boxWidth = ((0.f == boxWidth) ? attachSize.width : boxWidth);
	boxWidth += ((NSInteger)boxWidth % 2);			// to avoid interpolation
	boxHeight = ((0.f == boxHeight) ? attachSize.height : boxHeight);
	boxHeight += ((NSInteger)boxHeight % 2);
	
	boxRect = CGRectMake(kPopupMarginForShadow, kPopupMarginForShadow, boxWidth, boxHeight);
	self.frame = CGRectInset(boxRect, -kPopupMarginForShadow, -kPopupMarginForShadow);
	
	boxWidth += (2 * kPopupBoxPadding);
	boxHeight += (2 * kPopupBoxPadding);
	
	// placement - enough space at the top?
	if ((elementFrame.origin.y - statusBarHeight) > boxHeight) {
		position = 0;
		origin.y = elementFrame.origin.y - (boxHeight / 2);
		origin.x = refElementCenter.x;
	}
	
	// yes; enough space to the left?
	else if (elementFrame.origin.x > boxWidth) {
		position = 1;
		origin.y = refElementCenter.y;
		origin.x = elementFrame.origin.x - (boxWidth / 2);
	}
	
	// yes; enough space at the bottom?
	else if ((attachSize.height - (elementFrame.origin.y + elementFrame.size.height)) > boxHeight) {
		position = 2;
		origin.y = elementFrame.origin.y + elementFrame.size.height + (boxHeight / 2);
		origin.x = refElementCenter.x;
	}
	
	// yes; enough space to the right?
	else if ((attachSize.width - (elementFrame.origin.x + elementFrame.size.width)) > boxWidth) {
		position = 3;
		origin.y = refElementCenter.y;
		origin.x = elementFrame.origin.x + elementFrame.size.width + (boxWidth / 2);
	}
	
	// no, not enough space at all! TODO: Try smaller fontsizes; currently centering on screen
	else {
		position = -1;
		origin = refElementCenter;
		DLog(@"Not enough space for %fx%f -> implement smaller font sizes", boxWidth, boxHeight);
	}
	
	// check whether we're in bounds
	CGSize frameSize = attachToView.frame.size;
	
	if ((origin.x - (boxWidth / 2)) < 0.f) {
		origin.x = (boxWidth / 2);
	}
	else if ((origin.x + (boxWidth / 2)) > frameSize.width) {
		origin.x = frameSize.width - (boxWidth / 2);
	}
	
	if ((origin.y - (boxHeight / 2)) < statusBarHeight) {
		origin.y = statusBarHeight + (boxHeight / 2);
	}
	else if ((origin.y + (boxHeight / 2)) > frameSize.height) {
		origin.y = frameSize.height - (boxHeight / 2);
	}
	
	origin.x = roundf(origin.x);
	origin.y = roundf(origin.y);
	
	self.center = origin;
	self.layer.opacity = 0.f;
	
	// add to window and animate in
	[self.containerView addSubview:self];
	[attachToView addSubview:containerView];
	elementCenter = [self convertPoint:forElement.center fromView:[forElement superview]];
	
	[UIView beginAnimations:nil context:nil];
	//[UIView setAnimationDuration:0.1f];
	
	self.layer.opacity = 1.f;
	
	[UIView commitAnimations];
	
	// highlight forElement if possible
	if ([forElement isKindOfClass:[PPHintableLabel class]]) {
		[(PPHintableLabel *)forElement hintView:self didDisplayAnimated:YES];
	}
}

- (void) hide
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.4f];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideAnimationDidStop:finished:context:)];
	
	self.layer.opacity = 0.f;
	
	[UIView commitAnimations];
	
	// unhighlight forElement
	if ([forElement isKindOfClass:[PPHintableLabel class]]) {
		[(PPHintableLabel *)forElement hintView:self didHideAnimated:YES];
	}
}

- (void) hideAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[containerView removeFromSuperview];
	self.containerView = nil;
}
#pragma mark -



#pragma mark Touch Handling
- (CGRect) insideRect
{
	return self.frame;
	//return CGRectInset(self.frame, kPopupBoxPadding, kPopupBoxPadding);
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:[self superview]];
	
	// no longer touching the box, abort
	if (!CGRectContainsPoint([self insideRect], location)) {
		[self touchesCancelled:touches withEvent:event];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:[self superview]];
	
	// touch up inside - hide us
	if (CGRectContainsPoint([self insideRect], location)) {
		[self hide];
	}
}
#pragma mark -



#pragma mark Drawing
/*
 - (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
 {
 if (layer == containerView.layer) {
 
 }
 }	//	*/

- (void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// set general variables
	CGFloat borderRadius = 8.f;
	CGFloat borderWidth = 2.f;
	
	CGContextSaveGState(context);
	
	// create our outline path. Will be used multiple times
	CGPathRef outlinePath = createOutlinePath(position, boxRect, elementCenter, borderWidth, borderRadius);
	
	// draw box shadow
	CGContextAddRect(context, self.bounds);
	CGContextAddPath(context, outlinePath);
	CGContextEOClip(context);
	
	CGContextAddPath(context, outlinePath);
	CGContextSetShadowWithColor(context, CGSizeMake(0.f, [UIView shadowVerticalMultiplier] * kPopupShadowOffset), kPopupShadowBlurRadius, cgBoxShadowColor);
	CGContextSetFillColorWithColor(context, cgBlackColor);		// you won't see this, but this generates the shadow
	CGContextFillPath(context);
	
	CGContextRestoreGState(context);
	
	// draw the main background
	CGContextAddPath(context, outlinePath);
	CGContextClip(context);
	CGContextSaveGState(context);
	
	CGContextSetFillColorWithColor(context, cgBackgroundColor);
	CGContextFillRect(context, self.bounds);	
	
	// gloss
	CGFloat glossHeight = 34.f;
	
	CGPathRef glossPath = createGlossPath(boxRect, glossHeight);
	CGContextAddPath(context, glossPath);
	CGContextClip(context);
	
	CGPoint startPoint = CGPointMake(0.f, boxRect.origin.y - kPopupBoxPadding);
	CGPoint endPoint = CGPointMake(0.f, boxRect.origin.y + glossHeight);
	CGContextDrawLinearGradient(context, cgGlossGradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
	CGPathRelease(glossPath);
	
	CGContextRestoreGState(context);			// restore to the clipping before clipping to the gloss region
	
	// draw the border
	CGContextSetStrokeColorWithColor(context, cgBorderColor);
	CGContextSetLineWidth(context, (2 * borderWidth));					// width will be half of this setting due to the clipping
	CGContextAddPath(context, outlinePath);
	CGContextStrokePath(context);
	
	// clean up
	CGPathRelease(outlinePath);
}


- (void) initCGObjects
{
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	
	CGFloat backgroundColorComponents[4] = { 0.f, 0.1f, 0.3f, 0.85f };
	cgBackgroundColor = CGColorCreate(rgbColorSpace, backgroundColorComponents);
	
	CGFloat borderColorComponents[4] = { 1.f, 1.f, 1.f, 1.f };
	cgBorderColor = CGColorCreate(rgbColorSpace, borderColorComponents);
	
	CGFloat boxShadowColorComponents[4] = { 0.f, 0.f, 0.f, 0.75f };
	cgBoxShadowColor = CGColorCreate(rgbColorSpace, boxShadowColorComponents);
	
	CGFloat blackColorComponents[4] = { 0.f, 0.f, 0.f, 1.f };
	cgBlackColor = CGColorCreate(rgbColorSpace, blackColorComponents);
	
	CGFloat locations[2] = { 0.f, 1.f };
	CGFloat glossComponents[8] = {	1.f, 1.f, 1.f, 0.5f,			// Top color
		1.f, 1.f, 1.f, 0.1f };		// Bottom color
	cgGlossGradient = CGGradientCreateWithColorComponents(rgbColorSpace, glossComponents, locations, 2);
	
	CGColorSpaceRelease(rgbColorSpace);
}

- (void) releaseCGObjects
{
	if (NULL != cgBackgroundColor) {
		CGColorRelease(cgBackgroundColor);
	}
	if (NULL != cgBorderColor) {
		CGColorRelease(cgBorderColor);
	}
	if (NULL != cgBoxShadowColor) {
		CGColorRelease(cgBoxShadowColor);
	}
	if (NULL != cgBlackColor) {
		CGColorRelease(cgBlackColor);
	}
	if (NULL != cgGlossGradient) {
		CGGradientRelease(cgGlossGradient);
	}
}


CGMutablePathRef createOutlinePath(NSInteger pPosition, CGRect pRect, CGPoint elemCenter, CGFloat borderWidth, CGFloat borderRadius)
{
	CGFloat arrowOffset = kPopupBoxPadding;
	CGPoint arrowHead = CGPointMake(elemCenter.x, elemCenter.y);
	CGMutablePathRef path = CGPathCreateMutable();
	//NSLog(@"rect: %@", NSStringFromCGRect(pRect));
	
	// **** arrow points upwards (drawing clockwise)
	if (2 == pPosition) {
		arrowHead.y = pRect.origin.y - arrowOffset;
		
		CGFloat lRadius = borderRadius;
		CGFloat rRadius = borderRadius;
		
		if (arrowHead.x < pRect.origin.x + borderRadius + arrowOffset) {			// too far left
			if (arrowHead.x < pRect.origin.x + arrowOffset) {
				arrowHead.x = pRect.origin.x + arrowOffset;
				lRadius = 0.f;
			}
			else {
				lRadius = arrowHead.x - arrowOffset - pRect.origin.x;
			}
		}
		else if (arrowHead.x > pRect.origin.x + pRect.size.width - borderRadius - arrowOffset) {		// too far right
			if (arrowHead.x > pRect.origin.x + pRect.size.width - arrowOffset) {
				arrowHead.x = pRect.origin.x + pRect.size.width + arrowOffset;
				rRadius = 0.f;
			}
			else {
				rRadius = (pRect.origin.x + pRect.size.width) - (arrowHead.x + arrowOffset);
			}
		}
		
		// draw arrow side
		if (lRadius < 1.f) {
			CGPathMoveToPoint(path, NULL, pRect.origin.x, pRect.origin.y + borderWidth);
		}
		else {
			CGPathMoveToPoint(path, NULL, pRect.origin.x, pRect.origin.y + lRadius);
			CGPathAddArc(path, NULL, pRect.origin.x + lRadius, pRect.origin.y + lRadius, lRadius, M_PI, 1.5f * M_PI, 0);
			CGPathAddLineToPoint(path, NULL, arrowHead.x - arrowOffset, arrowHead.y + arrowOffset);
		}
		
		CGPathAddLineToPoint(path, NULL, arrowHead.x, arrowHead.y);
		CGPathAddLineToPoint(path, NULL, arrowHead.x + arrowOffset, arrowHead.y + arrowOffset);
		
		if (rRadius >= 1.f) {
			CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - rRadius, pRect.origin.y + rRadius, rRadius, 1.5f * M_PI, 0.f, 0);
		}
		
		// remaining body
		CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - borderRadius, pRect.origin.y + pRect.size.height - borderRadius, borderRadius, 0.f, 0.5f * M_PI, 0);
		CGPathAddArc(path, NULL, pRect.origin.x + borderRadius, pRect.origin.y + pRect.size.height - borderRadius, borderRadius, 0.5f * M_PI, M_PI, 0);
		CGPathCloseSubpath(path);
	}
	
	
	// **** arrow points right
	else if (1 == pPosition) {
		// TODO: Implement
		DLog(@"NOT IMPLEMENTED");
	}
	
	
	// **** arrow points downwards (drawing counterclockwise)
	else if (0 == pPosition) {
		arrowHead.y = pRect.origin.y + pRect.size.height + arrowOffset;
		
		CGFloat lRadius = borderRadius;
		CGFloat rRadius = borderRadius;
		
		if (arrowHead.x < pRect.origin.x + borderRadius + arrowOffset) {			// too far left
			if (arrowHead.x < pRect.origin.x + arrowOffset) {
				arrowHead.x = pRect.origin.x + arrowOffset;
				lRadius = 0.f;
			}
			else {
				lRadius = arrowHead.x - arrowOffset - pRect.origin.x;
			}
		}
		else if (arrowHead.x > pRect.origin.x + pRect.size.width - borderRadius - arrowOffset) {		// too far right
			if (arrowHead.x > pRect.origin.x + pRect.size.width - arrowOffset) {
				arrowHead.x = pRect.origin.x + pRect.size.width + arrowOffset;
				rRadius = 0.f;
			}
			else {
				rRadius = (pRect.origin.x + pRect.size.width) - (arrowHead.x + arrowOffset);
			}
		}
		
		// draw arrow side
		if (lRadius < 1.f) {
			CGPathMoveToPoint(path, NULL, pRect.origin.x, pRect.origin.y + pRect.size.height - borderWidth);
		}
		else {
			CGPathMoveToPoint(path, NULL, pRect.origin.x, pRect.origin.y + pRect.size.height - lRadius);
			CGPathAddArc(path, NULL, pRect.origin.x + lRadius, pRect.origin.y + pRect.size.height - lRadius, lRadius, M_PI, 0.5f * M_PI, 1);
			CGPathAddLineToPoint(path, NULL, arrowHead.x - arrowOffset, arrowHead.y - arrowOffset);
		}
		
		CGPathAddLineToPoint(path, NULL, arrowHead.x, arrowHead.y);
		CGPathAddLineToPoint(path, NULL, arrowHead.x + arrowOffset, arrowHead.y - arrowOffset);
		
		if (rRadius >= 1.f) {
			CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - rRadius, pRect.origin.y + pRect.size.height - rRadius, rRadius, 0.5f * M_PI, 0.f, 1);
		}
		
		
		// remaining body
		CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - borderRadius, pRect.origin.y + borderRadius, borderRadius, 0.f, 1.5f * M_PI, 1);
		CGPathAddArc(path, NULL, pRect.origin.x + borderRadius, pRect.origin.y + borderRadius, borderRadius, 1.5f * M_PI, M_PI, 1);
		CGPathCloseSubpath(path);
	}
	
	
	// **** arrow points left
	else if (3 == pPosition) {
		// TODO: Implement
		DLog(@"NOT IMPLEMENTED");
	}
	
	
	// **** no arrow
	else {
		CGFloat lRadius = borderRadius;
		CGFloat rRadius = borderRadius;
		
		CGPathMoveToPoint(path, NULL, pRect.origin.x, pRect.origin.y + pRect.size.height - lRadius);
		CGPathAddArc(path, NULL, pRect.origin.x + lRadius, pRect.origin.y + pRect.size.height - lRadius, lRadius, M_PI, 0.5f * M_PI, 1);
		CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - rRadius, pRect.origin.y + pRect.size.height - rRadius, rRadius, 0.5f * M_PI, 0.f, 1);
		CGPathAddArc(path, NULL, pRect.origin.x + pRect.size.width - borderRadius, pRect.origin.y + borderRadius, borderRadius, 0.f, 1.5f * M_PI, 1);
		CGPathAddArc(path, NULL, pRect.origin.x + borderRadius, pRect.origin.y + borderRadius, borderRadius, 1.5f * M_PI, M_PI, 1);
		CGPathCloseSubpath(path);
	}
	
	return path;		// don't forget to release this!
}


CGMutablePathRef createGlossPath(CGRect pRect, CGFloat glossHeight)
{
	CGPoint bo = pRect.origin;
	CGSize bs = pRect.size;
	bo.x -= kPopupBoxPadding;
	bo.y -= kPopupBoxPadding;
	bs.width += 2 * kPopupBoxPadding;
	bs.height += 2 * kPopupBoxPadding;
	
	glossHeight += kPopupBoxPadding;
	CGFloat glossBow = 12.f;
	
	// calculate the radius of the bow
	CGFloat tangensAlpha = (bs.width / 2) / (2 * glossBow);
	CGFloat radAlpha = (M_PI / 2) - atanf(tangensAlpha);
	CGFloat bowRadius = (bs.width / 2) / sinf(radAlpha);
	
	// create the gloss path
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, bo.x, bo.y);
	CGPathAddLineToPoint(path, NULL, bo.x + bs.width, bo.y);
	CGPathAddLineToPoint(path, NULL, bo.x + bs.width, bo.y + glossHeight - glossBow);
	CGPathAddArcToPoint(path, NULL, bo.x + bs.width / 2, bo.y + glossHeight + glossBow,
						bo.x, bo.y + glossHeight - glossBow, bowRadius);
	CGPathAddLineToPoint(path, NULL, bo.x, bo.y + glossHeight - glossBow);
	CGPathCloseSubpath(path);
	
	return path;
}


@end
