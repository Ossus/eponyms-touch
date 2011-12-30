//
//  TouchTableView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 24.08.08.
//	Copyright 2008 Pascal Pfiffner. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITableView subclass that supports a different action on double tap
// 

#import "TouchTableView.h"
#import "TouchTableViewDelegate.h"
#import "MCViewAnimations.h"


@interface TouchTableView ()

@property (nonatomic, retain) UILabel *noDataLabel;
@property (nonatomic, retain) NSIndexPath *indexPathOfLastSelectedRow;
//@property (nonatomic, retain) UIImageView *shadowView;

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect) optimalLabelFrame;

@end


@implementation TouchTableView

@synthesize allowsDoubleTap;
@synthesize indexPathOfLastSelectedRow;
@dynamic noDataHint;
@dynamic noDataLabel;
//@dynamic shadowView;


- (void) dealloc
{
	self.indexPathOfLastSelectedRow = nil;
	[noDataHint release];
	[noDataLabel release];
	
//	self.shadowView = nil;
	
	[super dealloc];
}

- (id) initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	if (self = [super initWithFrame:frame style:style]) {
		oldSeparatorStyle = UITableViewCellSeparatorStyleNone;
		allowsDoubleTap = YES;
	}
	return self;
}
#pragma mark -



#pragma mark Touch Delegate
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// we begin a double tap, cancel the delay request of the first tap
	UITouch *touch = [touches anyObject];
	if (2 == touch.tapCount) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{	
	// we have a touch NOT after initiating or stopping scrolling
	if (!self.dragging && !self.decelerating) {
		UITouch *touch = [touches anyObject];
		NSIndexPath *touchedRow = [self indexPathForRowAtPoint:[touch locationInView:self]];
		if (nil != touchedRow) {
			
			// second tap - perform action and de-select the cell selected on first tap
			if ((2 == touch.tapCount) && (indexPathOfLastSelectedRow == touchedRow)) {
				[self deselectRowAtIndexPath:touchedRow animated:NO];
				
				id tempDelegate = self.delegate;			// to circumvent a compiler warning (method not found in protocol)
				if (tempDelegate && [tempDelegate respondsToSelector:@selector(tableView:didDoubleTapRowAtIndexPath:)]) {
					[tempDelegate tableView:self didDoubleTapRowAtIndexPath:touchedRow];
				}
			}
			
			// first tap
			else {
				[self selectRowAtIndexPath:touchedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
				self.indexPathOfLastSelectedRow = touchedRow;
				
				if (allowsDoubleTap) {
					[self performSelector:@selector(didSelectRowAtIndexPath:) withObject:touchedRow afterDelay:0.25f];
				}
				else {
					[self didSelectRowAtIndexPath:touchedRow];
				}
			}
		}
	}
}
#pragma mark -



#pragma mark Action Handling
- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath == indexPathOfLastSelectedRow) {
		
		// inform the delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
			[self.delegate tableView:self didSelectRowAtIndexPath:indexPath];
		}
	}
}
#pragma mark -



#pragma mark No Data Label
- (NSString *) noDataHint
{
	return noDataHint;
}
- (void) setNoDataHint:(NSString *)newHint
{
	if (newHint != noDataHint) {
		[noDataHint release];
		noDataHint = [newHint copy];
		
		if (nil != noDataLabel) {
			noDataLabel.text = noDataHint;
			noDataLabel.frame = [self optimalLabelFrame];
		}
	}
}


- (UILabel *) noDataLabel
{
	if (nil == noDataLabel) {
		if (nil == noDataHint) {
			DLog(@"You must set the 'noDataHint' property before the label can be added");
			return nil;
		}
		
		self.noDataLabel = [[[UILabel alloc] initWithFrame:[self optimalLabelFrame]] autorelease];
		noDataLabel.backgroundColor = [UIColor clearColor];
		noDataLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		noDataLabel.font = [UIFont systemFontOfSize:15.f];
		noDataLabel.textAlignment = UITextAlignmentCenter;
		noDataLabel.textColor = [UIColor darkGrayColor];
		noDataLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
		noDataLabel.shadowOffset = CGSizeMake(0.f, 1.f);
		noDataLabel.lineBreakMode = UILineBreakModeWordWrap;
		noDataLabel.numberOfLines = 0;
		
		noDataLabel.text = self.noDataHint;
	}
	return noDataLabel;
}
- (void) setNoDataLabel:(UILabel *)newLabel
{
	if (newLabel != noDataLabel) {
		[noDataLabel release];
		noDataLabel = [newLabel retain];
	}
}

- (void) showNoDataLabelAnimated:(BOOL)animated
{
	if (noDataHint && ![self.noDataLabel superview]) {
		if (UITableViewCellSeparatorStyleNone != self.separatorStyle) {
			oldSeparatorStyle = self.separatorStyle;
			self.separatorStyle = UITableViewCellSeparatorStyleNone;
		}
		
		noDataLabel.text = noDataHint;
		noDataLabel.frame = [self optimalLabelFrame];
		if (animated) {
			[self addSubviewAnimated:noDataLabel];
		}
		else {
			[self addSubview:noDataLabel];
		}
	}
}

- (void) hideNoDataLabelAnimated:(BOOL)animated
{
	if (animated) {
		[noDataLabel removeFromSuperviewAnimated];
	}
	else {
		[noDataLabel removeFromSuperview];
	}
	
	if (UITableViewCellSeparatorStyleNone != oldSeparatorStyle) {
		self.separatorStyle = oldSeparatorStyle;
	}
}


/*
- (UIImageView *) shadowView
{
	if (nil == shadowView) {
		self.shadowView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shadow_bottom.png"]] autorelease];
	}
	return shadowView;
}
- (void) setShadowView:(UIImageView *)newView
{
	if (newView != shadowView) {
		[shadowView release];
		shadowView = [newView retain];
	}
}


- (void) setContentOffset:(CGPoint)offset
{
	[super setContentOffset:offset];
	
	// adjust shadow
	BOOL hasSuperview = (shadowView && (nil != [shadowView superview]));
	if (offset.y < -5.f) {
		if (!hasSuperview) {
			[self insertSubview:self.shadowView atIndex:0];
		}
		
		CGRect frm = shadowView.frame;
		frm.size.width = [self frame].size.width;
		frm.origin.y = offset.y;
		shadowView.frame = frm;
	}
	else {
		if (hasSuperview) {
			[shadowView removeFromSuperviewAnimated];
		}
	}
}	//	*/
#pragma mark -



#pragma mark Utilities
- (CGRect) optimalLabelFrame
{
	CGFloat originY = 0.f;
	CGRect tableRect = [self frame];
	CGFloat tableHeight = tableRect.size.height;
	if (nil != self.tableHeaderView) {
		originY = [self.tableHeaderView bounds].size.height;
		tableHeight -= originY;
	}
	if (nil != self.tableFooterView) {
		tableHeight -= [self.tableFooterView bounds].size.height;
	}
	
	// get size needed from string
	CGSize maxSize = CGSizeMake(tableRect.size.width - 40.f, tableHeight);
	UIFont *lblFont = noDataLabel ? noDataLabel.font : [UIFont systemFontOfSize:15.f];
	CGSize neededSize = [noDataHint sizeWithFont:lblFont constrainedToSize:maxSize];
	CGFloat height = fmaxf(noDataLabel.font.leading, neededSize.height);
	
	return CGRectMake(20.f, roundf(originY + (tableHeight / 2 - height / 2)), maxSize.width, height);
}


@end
