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
#import "PPHintableLabel.h"
#import <QuartzCore/QuartzCore.h>
//#import "UIView+Utilities.h"

#define kPopupBoxPadding 10.0			///< min distance to screen edges
#define kPopupElementDistance 10.0		///< distance to the referring element
#define kPopupMarginForShadow 30.0		///< the frame will be this much bigger
#define kPopupShadowOffset 6.0			///< shadow offset downwards
#define kPopupShadowBlurRadius 18.0		///< shadow blur radius
#define kPopupTextXPadding 12.0
#define kPopupTextYPadding 8.0
#define kPopupTitleLabelHeight 20.0


@interface PPHintView ()

@property (nonatomic, readwrite, strong) MCOverlayManager *overlayManager;
@property (nonatomic, strong) UIFont *originalTitleFont;
@property (nonatomic, strong) UIFont *originalTextFont;
@property (nonatomic, strong) UIView *textContainer;

- (CGPoint)adjustAndCenterIn:(UIView *)hostView forView:(UIView *)targetView;

- (void)initCGObjects;
CGMutablePathRef createOutlinePath(NSInteger pPosition, CGRect pRect, CGPoint arrowHead, CGFloat borderWidth, CGFloat borderRadius);
CGMutablePathRef createGlossPath(CGRect pRect, CGFloat glossHeight);

@end
#pragma mark -


@implementation PPHintView

@synthesize forElement, resignFirstResponderUponHide, dismissBlock;
@synthesize overlayManager;
@synthesize titleLabel, textLabel;
@synthesize originalTitleFont, originalTextFont;
@synthesize textContainer;


- (void)dealloc
{
	CGColorRelease(cgBackgroundColor);
	CGColorRelease(cgBorderColor);
	CGColorRelease(cgBoxShadowColor);
	CGColorRelease(cgBlackColor);
	CGGradientRelease(cgGlossGradient);
	
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		[super setBackgroundColor:[UIColor clearColor]];
		//[super setBackgroundColor:[UIColor colorWithRed:0.f green:0.f blue:1.f alpha:0.3f]];
		self.opaque = NO;
		self.userInteractionEnabled = YES;
		resignFirstResponderUponHide = YES;
		
		// create the colors
		[self initCGObjects];
    }
	
    return self;
}

+ (PPHintView *)hintViewForView:(UIView *)forView;
{
	CGRect appRect = [[UIScreen mainScreen] bounds];
	PPHintView *view = [[self alloc] initWithFrame:appRect];
	view.forElement = forView;
	
	return view;
}



#pragma mark - KVC
- (UILabel *)titleLabel
{
	if (!titleLabel) {
		CGRect frame = CGRectInset(self.textContainer.bounds, kPopupTextXPadding, kPopupTextYPadding);
		frame.size.height = kPopupTitleLabelHeight;
		
		self.titleLabel = [[UILabel alloc] initWithFrame:frame];
		titleLabel.opaque = NO;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textColor = [UIColor whiteColor];
		titleLabel.font = self.originalTitleFont = [UIFont boldSystemFontOfSize:17.f];
		titleLabel.adjustsFontSizeToFitWidth = YES;
		titleLabel.shadowColor = [UIColor colorWithWhite:0.f alpha:0.9f];
		titleLabel.shadowOffset = CGSizeMake(0.f, -1.f);
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		
		[textContainer addSubview:titleLabel];
	}
	
	return titleLabel;
}
- (void)setTitleLabel:(UILabel *)newTitleLabel
{
	if (newTitleLabel != titleLabel) {
		if (nil != [titleLabel superview]) {
			[titleLabel removeFromSuperview];
		}
		titleLabel = newTitleLabel;
	}
}

- (UILabel *)textLabel
{
	if (nil == textLabel) {
		CGRect frame = CGRectInset(self.textContainer.bounds, kPopupTextXPadding, kPopupTextYPadding);
		CGFloat topPadding = titleLabel ? (kPopupTitleLabelHeight + kPopupTextYPadding / 2) : 0.f;
		frame.origin.y += topPadding;
		frame.size.height -= topPadding;
		
		self.textLabel = [[UILabel alloc] initWithFrame:frame];
		textLabel.opaque = NO;
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.font = self.originalTextFont = [UIFont systemFontOfSize:15.f];
		textLabel.shadowColor = [UIColor colorWithWhite:0.f alpha:0.9f];
		textLabel.shadowOffset = CGSizeMake(0.f, -1.f);
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		textLabel.numberOfLines = 100;
		
		[textContainer addSubview:textLabel];
	}
	
	return textLabel;
}
- (void)setTextLabel:(UILabel *)newTextLabel
{
	if (newTextLabel != textLabel) {
		if (nil != [textLabel superview]) {
			[textLabel removeFromSuperview];
		}
		textLabel = newTextLabel;
	}
}

- (UIView *)textContainer
{
	if (!textContainer) {
		CGRect aFrame = CGRectInset(self.bounds, kPopupMarginForShadow, kPopupMarginForShadow);
		
		self.textContainer = [[UIView alloc] initWithFrame:aFrame];
		textContainer.opaque = NO;
		textContainer.backgroundColor = [UIColor clearColor];
		
		[self addSubview:textContainer];
	}
	return textContainer;
}

/**
 *	Setting the background color leaves super's background color intact but assigns a private value just so we know it.
 *	Also creates the required CG color
 */
- (void)setBackgroundColor:(UIColor *)aColor
{
	if (aColor != myBackgroundColor) {
		myBackgroundColor = aColor;
		
		CGColorRelease(cgBackgroundColor);
		cgBackgroundColor = myBackgroundColor ? CGColorRetain([myBackgroundColor CGColor]) : NULL;
		
		[self setNeedsDisplay];
	}
}

- (UIColor *)backgroundColor
{
	return myBackgroundColor;
}



#pragma mark - Showing/Hiding
/**
 *	Shows the hint view
 */
- (void)show
{
	if (nil == forElement) {
		ALog(@"Cannot show without an element to point to");
		return;
	}
	if (!titleLabel.text && !textLabel.text) {
		ALog(@"No use to show without any text");
		return;
	}
	
	// prepare overlay
	self.overlayManager = [MCOverlayManager new];
	overlayManager.delegate = self;
	overlayManager.inAnimation = MCAnimationTypeFadeInOut;
	overlayManager.outAnimation = MCAnimationTypeFadeInOut;
	overlayManager.alignOnScreen = NO;
	overlayManager.pollPosition = YES;
	
	// size according to coordinate system of the overlay
	[overlayManager overlaySizeForView:[forElement superview]];
	CGPoint origin = [self adjustAndCenterIn:overlayManager forView:forElement];
	
	// present according to OUR coordinate system (!!!)
	[overlayManager overlay:self
				 withCenter:[overlayManager convertPoint:origin toView:[forElement superview]]
					 inView:[forElement superview]];
}


/**
 *	Repositions the hint view to point at the given targetView
 *	@param hostView Usually our superview
 *	@param targetView The view we should point to
 */
- (CGPoint)adjustAndCenterIn:(UIView *)hostView forView:(UIView *)targetView
{
	CGSize attachSize = [hostView bounds].size;
	CGRect elementFrame = [hostView convertRect:targetView.frame fromView:[targetView superview]];
	CGPoint currentCenter = self.center;
	
	// calculate needed dimensions based on the titleLabel (width) and textView (height)
	BOOL tooBig = YES;
	CGFloat boxWidth = 0.f;
	CGFloat boxHeight = 0.f;
	CGPoint origin = [hostView convertPoint:targetView.center fromView:[targetView superview]];
	CGSize fitSize = CGSizeZero;
	
	while (tooBig) {
		tooBig = NO;
		boxWidth = 0.f;
		boxHeight = 0.f;
		
		
		// ** DETERMINE SIZE; according to title label first
		if (titleLabel.text) {
			CGSize labelSize = [titleLabel.text sizeWithFont:titleLabel.font];
			boxWidth = fminf(labelSize.width + (2 * kPopupTextXPadding), attachSize.width - (2 * kPopupBoxPadding));
			boxHeight = kPopupTextYPadding + kPopupTitleLabelHeight + kPopupTextYPadding / 2;
		}
		
		// determine text label size
		if (textLabel.text) {
			CGFloat maxBoxWidth = fmaxf(boxWidth + (2 * kPopupTextXPadding), attachSize.width - (2 * kPopupBoxPadding));
			CGSize maxSize = CGSizeMake(maxBoxWidth - (2 * kPopupTextXPadding), CGFLOAT_MAX);
			CGSize textSize = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:maxSize];
			CGFloat widthHeightRatio = textSize.width / textSize.height;
			
			// especially on the iPad, we don't want to have a view the whole screen wide but only one or two lines of text (except the title is that wide)
			CGFloat refWidth = fmaxf(boxWidth, 320.f - 2 * kPopupBoxPadding);
			if (widthHeightRatio > 4.f && textSize.width > refWidth) {
				maxSize.width = fmaxf(refWidth, textSize.width / (widthHeightRatio / 3));		// 3 is approx. the target ratio
				textSize = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:maxSize];
			}
			
			// set box height according to needed size
			boxHeight = [textLabel frame].origin.y + textSize.height + kPopupTextYPadding;
			boxWidth = fmaxf(boxWidth, textSize.width + 2 * kPopupTextXPadding);
		}
		
		// assure we don't have zero width/height and have an even size
		boxWidth = ((boxWidth < 20.f) ? attachSize.width - (2 * kPopupBoxPadding) : boxWidth);
		boxWidth += ((NSInteger)boxWidth % 2);			// needed to avoid interpolation
		boxHeight = ((boxHeight < 20.f) ? attachSize.height - (2 * kPopupBoxPadding) : boxHeight);
		boxHeight += ((NSInteger)boxHeight % 2);
		
		boxRect = CGRectMake(kPopupMarginForShadow, kPopupMarginForShadow, boxWidth, boxHeight);
		self.frame = CGRectInset(boxRect, -kPopupMarginForShadow, -kPopupMarginForShadow);
		self.center = currentCenter;			// to avoid reposition artifacts
		self.textContainer.frame = boxRect;
		
		boxWidth += (2 * kPopupBoxPadding);
		boxHeight += (2 * kPopupBoxPadding);
		
		// ** PLACEMENT; check where we fit in
		fitSize = CGSizeMake(boxWidth + (2 * kPopupBoxPadding), boxHeight + (2 * kPopupBoxPadding) + kPopupShadowOffset);
		
		// enough space at the top?
		if (elementFrame.origin.y > fitSize.height) {
			position = 0;
			origin.y = elementFrame.origin.y - (boxHeight / 2);
		}
		
		// no; enough space at the bottom?
		else if (attachSize.height - (elementFrame.origin.y + elementFrame.size.height) > fitSize.height) {
			position = 2;
			origin.y = elementFrame.origin.y + elementFrame.size.height + (boxHeight / 2);
		}
		
		// no; enough space to the left?
		else if (elementFrame.origin.x > fitSize.width) {
			position = 1;
			origin.x = elementFrame.origin.x - (boxWidth / 2);
		}
		
		// no; enough space to the right?
		else if ((attachSize.width - (elementFrame.origin.x + elementFrame.size.width)) > fitSize.width) {
			position = 3;
			origin.x = elementFrame.origin.x + elementFrame.size.width + (boxWidth / 2);
		}
		
		// not enough space at all for an arrow, try putting it over the label
		else if (fitSize.height <= attachSize.height && fitSize.width <= attachSize.width) {
			position = -1;
		}
		
		// no, not enough space at all!
		else {
			position = -1;
			tooBig = YES;
		}
		
		// try smaller fontsize
		if (tooBig) {
			if (titleLabel) {
				CGFloat titleSize = titleLabel.font.pointSize - 1.f;
				if (titleSize < 12.f) {
					DLog(@"Already shrunk title font to 12 points, stopping here. Not enough space for %fx%f, only got %fx%f", boxWidth, boxHeight, attachSize.width, attachSize.height);
					break;
				}
				titleLabel.font = [titleLabel.font fontWithSize:titleSize];
			}
			
			if (textLabel) {
				CGFloat textSize = textLabel.font.pointSize - 1.f;
				if (textSize < 12.f) {
					DLog(@"Already shrunk text font to 12 points, stopping here. Not enough space for %fx%f, only got %fx%f", boxWidth, boxHeight, attachSize.width, attachSize.height);
					break;
				}
				textLabel.font = [textLabel.font fontWithSize:textSize];
			}
		}
	}
	
	
	// ** BOUNDS CHECK
	if ((origin.x - (fitSize.width / 2)) < 0.f) {
		origin.x = (boxWidth / 2);
	}
	else if ((origin.x + (fitSize.width / 2)) > attachSize.width) {
		origin.x = attachSize.width - (boxWidth / 2);
	}
	
	if ((origin.y - (fitSize.height / 2)) < 0.f) {
		origin.y = (boxHeight / 2);
	}
	else if ((origin.y + (fitSize.height / 2)) > attachSize.height) {
		origin.y = attachSize.height - (boxHeight / 2);
	}
	
	origin.x = roundf(origin.x);
	origin.y = roundf(origin.y);
	
	return origin;
}


- (void)hide
{
	[overlayManager hideOverlayAnimated:YES];
}



#pragma mark - MCOverlayManagerDelegate
- (BOOL)overlayShouldReposition:(MCOverlayManager *)overlay
{
	CGPoint origin = [self adjustAndCenterIn:overlay forView:forElement];
	[overlay moveOverlayTo:[overlay convertPoint:origin toView:[forElement superview]] animated:YES];
	[self setNeedsDisplay];
	
	// return NO as we do this ourselves
	return NO;
}

- (void)willDismissOverlay:(MCOverlayManager *)overlay
{
	// un-highlight forElement if possible
	if (resignFirstResponderUponHide && [forElement respondsToSelector:@selector(resignFirstResponder)]) {
		[forElement performSelector:@selector(resignFirstResponder)];
	}
	
	// callback
	if (dismissBlock) {
		dismissBlock();
		self.dismissBlock = nil;
	}
}



#pragma mark - Touch Handling
- (CGRect)insideRect
{
	return self.frame;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:[self superview]];
	
	// no longer touching the box, abort
	if (!CGRectContainsPoint([self insideRect], location)) {
		[self touchesCancelled:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:[self superview]];
	
	// touch up inside - hide us
	if (CGRectContainsPoint([self insideRect], location)) {
		[self hide];
	}
}



#pragma mark Drawing
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// set general variables
	CGFloat borderRadius = 8.f;
	CGFloat borderWidth = 2.f;
	
	CGContextSaveGState(context);
	
	// create our outline path. Will be used multiple times
	CGPoint elemCenter = [self convertPoint:forElement.center fromView:[forElement superview]];
	CGPathRef outlinePath = createOutlinePath(position, boxRect, elemCenter, borderWidth, borderRadius);
	
	// draw box shadow
	CGContextAddRect(context, self.bounds);
	CGContextAddPath(context, outlinePath);
	CGContextEOClip(context);
	
	CGContextAddPath(context, outlinePath);
	CGContextSetShadowWithColor(context, CGSizeMake(0.f, kPopupShadowOffset), kPopupShadowBlurRadius, cgBoxShadowColor);
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


- (void)initCGObjects
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
	CGFloat glossComponents[8] = {	1.f, 1.f, 1.f, 0.5f,		// Top color
									1.f, 1.f, 1.f, 0.1f };		// Bottom color
	cgGlossGradient = CGGradientCreateWithColorComponents(rgbColorSpace, glossComponents, locations, 2);
	
	CGColorSpaceRelease(rgbColorSpace);
}


@end


CGMutablePathRef createOutlinePath(NSInteger pPosition, CGRect pRect, CGPoint arrowHead, CGFloat borderWidth, CGFloat borderRadius)
{
	CGFloat arrowOffset = kPopupBoxPadding;
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

