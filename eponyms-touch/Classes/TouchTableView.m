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


@implementation TouchTableView

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	// we begin a double tap, cancel the delay request of the first tap
	if(2 == touch.tapCount) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
	else {
		[super touchesBegan:touches withEvent:event];
	}
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch *touch = [touches anyObject];
	
	// second tap - perform action after de-selecting the cell selected on first tap
	if(2 == touch.tapCount) {
		NSIndexPath *doubleTappedRow = [self indexPathForSelectedRow];
		[self deselectRowAtIndexPath:doubleTappedRow animated:NO];
		
		if(self.delegate && [self.delegate conformsToProtocol:@protocol(TouchTableViewDelegate)]) {
			[self.delegate tableView:self didDoubleTapRowAtIndexPath:doubleTappedRow];
		}
	}
	
	// other. Maybe swipe gesture, maybe triple tap, whatever
	else if(lastTouchWasSwipeEvent || (1 != touch.tapCount)) {
		lastTouchWasSwipeEvent = (0 == touch.tapCount);
		[super touchesEnded:touches withEvent:event];
	}
	
	// first tap
	else {
		if(touch.window) {			// the method seems to be called 2 times, but once with window=nil, so just ignore that second call
			[self performSelector:@selector(singleTapEndedWithObjects:) withObject:[NSArray arrayWithObjects:touches, event, nil] afterDelay:0.25];
		}
	}
}

- (void) singleTapEndedWithObjects:(NSArray *)objects
{
	NSSet *touches = [objects objectAtIndex:0];
	UIEvent *event = [objects objectAtIndex:1];
	
	[super touchesEnded:touches withEvent:event];
}


@end
