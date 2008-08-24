//
//  EponymTextView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 24.08.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITextView subclass that draws rounded corners for eponyms-touch
// 

#import "TouchTableView.h"
#import "TouchTableViewDelegate.h"


@implementation TouchTableView

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	// we begin a double tap, cancel the delay request of the first tap
	UITouch *touch = [touches anyObject];
	if(2 == touch.tapCount) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch *touch = [touches anyObject];
	CGFloat topOffset = [self bounds].origin.y;
	if(!topOffsetAfterLastTouchEvent) {
		topOffsetAfterLastTouchEvent = topOffset;
	}
	
	// we have a first or second touch NOT after a swipe event
	if((topOffset == topOffsetAfterLastTouchEvent) && (touch.tapCount < 3 && touch.tapCount > 0)) {
		
		// second tap - perform action and de-select the cell selected on first tap
		if(2 == touch.tapCount) {
			NSIndexPath *doubleTappedRow = [self indexPathForRowAtPoint:[touch locationInView:self]];
			[self selectRowAtIndexPath:doubleTappedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
			// otherwise, for too fast double taps, the cell will not visually update, not even after calling setNeedsDisplay
			
			id tempDelegate = self.delegate;		// to circumvent a compiler warning (method not found in protocol)
			if(tempDelegate && [tempDelegate conformsToProtocol:@protocol(TouchTableViewDelegate)]) {
				[tempDelegate tableView:self didDoubleTapRowAtIndexPath:doubleTappedRow];
			}
			
			[self deselectRowAtIndexPath:doubleTappedRow animated:NO];
		}
		
		// first tap
		else {
			if(touch.window) {			// the method seems to be called 2 times, but once with window=nil, so just ignore that second call
				[self performSelector:@selector(singleTapEndedWithObjects:) withObject:[NSArray arrayWithObjects:touches, event, nil] afterDelay:0.25];
			}
		}
	}
	
	// other. Maybe swipe gesture, maybe triple tap, whatever
	else {
		[super touchesEnded:touches withEvent:event];
	}
	
	topOffsetAfterLastTouchEvent = topOffset;
}

- (void) singleTapEndedWithObjects:(NSArray *)objects
{
	NSSet *touches = [objects objectAtIndex:0];
	UIEvent *event = [objects objectAtIndex:1];
	
	[super touchesEnded:touches withEvent:event];
}



@end
