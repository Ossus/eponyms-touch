//
//  ListViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the eponym list view for eponyms-touch
//  


#import <UIKit/UIKit.h>
#import "MCTableViewController.h"


@interface ListViewController : MCTableViewController <UISearchBarDelegate> {
	id delegate;
	
	NSArray *eponymArrayCache;
	NSArray *eponymSectionArrayCache;
	
	UISearchBar *mySearchBar;
	UIBarButtonItem *initSearchButton;
	UIBarButtonItem *abortSearchButton;
	NSTimer *searchTimeoutTimer;
	BOOL isSearching;
}

@property (nonatomic, assign) id delegate;

@property (nonatomic, retain) NSArray *eponymArrayCache;				// 2 dimensional array, 1st dimension first letter, 2nd dimension its eponyms
@property (nonatomic, retain) NSArray *eponymSectionArrayCache;			// 1 dimensional, first letters

@property (nonatomic, retain) UISearchBar *mySearchBar;
@property (nonatomic, retain) UIBarButtonItem *initSearchButton;
@property (nonatomic, retain) UIBarButtonItem *abortSearchButton;
@property (nonatomic, retain) NSTimer *searchTimeoutTimer;

- (void) cacheEponyms:(NSArray *)eponyms andHeaders:(NSArray *)sections;

- (void) assureEponymSelectedInListAnimated:(BOOL)animated;
- (void) assureSelectedEponymStarredInList;
- (void) assureEponymAtIndexPathStarredInList:(NSIndexPath *)indexPath;


@end