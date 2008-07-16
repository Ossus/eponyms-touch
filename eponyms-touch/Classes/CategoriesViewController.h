//
//  CategoriesViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  Copyright 2008 home sweet home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CategoriesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	id delegate;
	
	NSArray *categoryArrayCache;
	UITableView *myTableView;
	
	CGFloat atLaunchScrollTo;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSArray *categoryArrayCache;
@property (nonatomic, retain) UITableView *myTableView;

@property (nonatomic, assign) CGFloat atLaunchScrollTo;

@end
