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

#import <UIKit/UIKit.h>


@interface TouchTableView : UITableView {
	BOOL allowsDoubleTap;							// YES by default
	
	NSString *noDataHint;
	
	@private
	UILabel *noDataLabel;
	NSIndexPath *indexPathOfLastSelectedRow;
	UITableViewCellSeparatorStyle oldSeparatorStyle;
	
//	UIImageView *shadowView;
}

@property (nonatomic, assign) BOOL allowsDoubleTap;
@property (nonatomic, copy) NSString *noDataHint;

- (void) showNoDataLabelAnimated:(BOOL)animated;
- (void) hideNoDataLabelAnimated:(BOOL)animated;


@end

