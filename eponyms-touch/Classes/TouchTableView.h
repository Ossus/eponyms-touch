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

#import <UIKit/UIKit.h>


@interface TouchTableView : UITableView {
	NSIndexPath *indexPathOfLastSelectedRow;
}

@property (nonatomic, retain) NSIndexPath *indexPathOfLastSelectedRow;

- (void) immediatelySelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

