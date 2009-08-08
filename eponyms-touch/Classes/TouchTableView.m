//
//  TouchTableView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 24.08.08.
//	Copyright 2009 Pascal Pfiffner. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITableView subclass that supports a different action on double tap
// 

#import "TouchTableView.h"
#import "TouchTableViewDelegate.h"


@implementation TouchTableView

@synthesize indexPathOfLastSelectedRow;


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
	// we have a touch NOT after initiating or stopping scrolling
	if(!self.dragging && !self.decelerating) {
		UITouch *touch = [touches anyObject];
		NSIndexPath *touchedRow = [self indexPathForRowAtPoint:[touch locationInView:self]];
		
		// second tap - perform action and de-select the cell selected on first tap
		if((2 == touch.tapCount) && (indexPathOfLastSelectedRow == touchedRow)) {
			id tempDelegate = self.delegate;		// to circumvent a compiler warning (method not found in protocol)
			if(tempDelegate && [tempDelegate conformsToProtocol:@protocol(TouchTableViewDelegate)]) {
				[tempDelegate tableView:self didDoubleTapRowAtIndexPath:touchedRow];
			}
			
			[self deselectRowAtIndexPath:touchedRow animated:NO];
		}
		
		// first tap
		else {
			if(touch.window) {			// the method seems to be called 2 times, but once with window=nil, so just ignore that second call
				[super touchesEnded:nil withEvent:event];
				self.indexPathOfLastSelectedRow = touchedRow;
				[self performSelectorInBackground:@selector(immediatelySelectRowAtIndexPath:) withObject:touchedRow];
				[self performSelector:@selector(didSelectRowAtIndexPath:) withObject:touchedRow afterDelay:0.25];
			}
		}
	}
	
	// other. Maybe swipe gesture, maybe triple tap, whatever
	else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void) immediatelySelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	[pool drain];
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.delegate && (indexPath == indexPathOfLastSelectedRow)) {
		[self.delegate tableView:self didSelectRowAtIndexPath:indexPath];
	}
}


@end
