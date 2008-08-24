//
//  EponymTextView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITextView subclass that draws rounded corners for eponyms-touch
//  

#import "EponymTextView.h"


@implementation EponymTextView

@synthesize borderWidth, borderRadius, borderColor, fillColor;		//, font, text;


- (id) initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];
	if(self) {
		self.borderWidth = 1.0;
		self.borderRadius = 10.0;
		self.borderColor = [UIColor colorWithWhite:0.65 alpha:1.0];
		self.fillColor = [UIColor whiteColor];
		self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];			// this always draws anyway, so we use our fillColor to circumvent this
	}
	return self;
}

// This is why we're even here
- (void) drawRect:(CGRect) rect
{
	CGRect localRect = CGRectInset(rect, self.borderWidth / 2, self.borderWidth / 2);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGContextTranslateCTM(context, self.borderWidth / 2, self.borderWidth / 2);
	
	// create the border - we start at the top left edge (without including the edge itself) and move around counter-clockwise
	CGContextMoveToPoint(context, 0.0, self.borderRadius);
	CGContextAddLineToPoint(context, 0.0, (localRect.size.height - self.borderRadius));
	CGContextAddCurveToPoint(context, 0.0, localRect.size.height,
							 self.borderRadius, localRect.size.height,
							 self.borderRadius, localRect.size.height);
	
	CGContextAddLineToPoint(context, (localRect.size.width - self.borderRadius), localRect.size.height);
	CGContextAddCurveToPoint(context, localRect.size.width, localRect.size.height,
							 localRect.size.width, (localRect.size.height - self.borderRadius),
							 localRect.size.width, (localRect.size.height - self.borderRadius));
	
	CGContextAddLineToPoint(context, localRect.size.width, self.borderRadius);
	CGContextAddCurveToPoint(context, localRect.size.width, 0.0,
							 localRect.size.width - self.borderRadius, 0.0,
							 localRect.size.width - self.borderRadius, 0.0);
	
	CGContextAddLineToPoint(context, self.borderRadius, 0.0);
	CGContextAddCurveToPoint(context, 0.0, 0.0,
							 0.0, self.borderRadius,
							 0.0, self.borderRadius);
	
	CGContextClosePath(context);
	
	CGContextRestoreGState(context);
	
	// draw
	[self.fillColor setFill];
	[self.borderColor setStroke];
	CGContextSetLineWidth(context, self.borderWidth);
	
	CGContextDrawPath(context, kCGPathFillStroke);
}


/*- (CGSize) sizeThatFits:(CGSize)size
{
}*/


- (void) dealloc
{
	[borderColor release];			borderColor = nil;
	[fillColor release];			fillColor = nil;
	
	[super dealloc];
}


@end
