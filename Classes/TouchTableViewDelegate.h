//
//  TouchTableViewDelegate.h
//  eponyms-touch + medcalc
//
//  Created by Pascal Pfiffner on 24.08.08.
//	Copyright 2008 MedCalc. All rights reserved.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Protocol for the delegate of a TouchTableView, a UITableView subclass supporting doubletaps
// 

#import <UIKit/UIKit.h>
@class TouchTableView;

@protocol TouchTableViewDelegate <NSObject, UITableViewDelegate>

@optional
- (void) tableView:(TouchTableView *)aTableView didDoubleTapRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) tableView:(TouchTableView *)aTableView rowIsVisible:(NSIndexPath *)indexPath;

@end
