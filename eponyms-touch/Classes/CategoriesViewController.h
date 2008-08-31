//
//  CategoriesViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the categories view for eponyms-touch
//  


#import <UIKit/UIKit.h>


@interface CategoriesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	id delegate;
	
	NSArray *categoryArrayCache;
	UITableView *myTableView;
	
	CGFloat atLaunchScrollTo;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSArray *categoryArrayCache;
@property (nonatomic, retain) UITableView *myTableView;

@property (nonatomic, assign) CGFloat atLaunchScrollTo;


- (void) showNewEponymsAvailable:(BOOL)hasNew;

@end
