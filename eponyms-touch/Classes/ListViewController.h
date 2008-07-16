//
//  ListViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  Copyright 2008 home sweet home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
	id delegate;
	
	NSArray *eponymArrayCache;
	NSArray *eponymSectionArrayCache;
	
	UITableView *myTableView;
	UISearchBar *mySearchBar;
	UIBarButtonItem *initSearchButton;
	UIBarButtonItem *abortSearchButton;
	//UIView *mySearchLens;
	
	CGFloat atLaunchScrollTo;
}

@property (nonatomic, retain) id delegate;

@property (nonatomic, retain) NSArray *eponymArrayCache;				// 2 dimensional array, 1st dimension first letter, 2nd dimension its eponyms
@property (nonatomic, retain) NSArray *eponymSectionArrayCache;			// 1 dimensional, first letters

@property (nonatomic, retain) UITableView *myTableView;
@property (nonatomic, retain) UISearchBar *mySearchBar;
@property (nonatomic, retain) UIBarButtonItem *initSearchButton;
@property (nonatomic, retain) UIBarButtonItem *abortSearchButton;
//@property (nonatomic, retain) UIView *mySearchLens;

@property (nonatomic, assign) CGFloat atLaunchScrollTo;

- (void) cacheEponyms:(NSArray *) eponyms andHeaders:(NSArray *) sections;

@end
