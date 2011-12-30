//
//  MCTableViewController.h
//  medcalc
//
//  Created by Pascal Pfiffner on 09.01.10.
//	Copyright 2010 MedCalc. All rights reserved.
//	This sourcecode is released under the Apache License, Version 2.0
//	http://www.apache.org/licenses/LICENSE-2.0.html/
//  
//  A tableviewcontroller that can save its state automatically. Uses TouchTableView instead of UITableView.
//  

#import <UIKit/UIKit.h>
#import "MCViewController.h"
#import "TouchTableViewDelegate.h";
#import "TouchTableView.h"
 

@interface MCTableViewController : MCViewController <TouchTableViewDelegate, UITableViewDataSource> {
	UITableViewStyle tableStyle;							// only effective if set before calling loadView!
	TouchTableView *tableView;
	
	NSString *noDataHint;
	
	@private
	BOOL shouldShowDataHintAfterLoading;
}

@property (nonatomic, assign) UITableViewStyle tableStyle;
@property (nonatomic, retain) TouchTableView *tableView;
@property (nonatomic, copy) NSString *noDataHint;

- (id) initWithStyle:(UITableViewStyle)style;

- (void) showNoDataHintAnimated:(BOOL)animated;
- (void) hideNoDataHintAnimated:(BOOL)animated;


@end
