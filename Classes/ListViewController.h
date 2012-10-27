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
	BOOL isSearching;
}

@property (nonatomic, unsafe_unretained) id delegate;

@property (nonatomic, strong) NSArray *eponymArrayCache;				// 2 dimensional array, 1st dimension first letter, 2nd dimension its eponyms
@property (nonatomic, strong) NSArray *eponymSectionArrayCache;			// 1 dimensional, first letters

@property (nonatomic, strong) UISearchBar *mySearchBar;
@property (nonatomic, strong) UIBarButtonItem *initSearchButton;
@property (nonatomic, strong) UIBarButtonItem *abortSearchButton;
@property (nonatomic, strong) NSTimer *searchTimeoutTimer;

- (void)cacheEponyms:(NSArray *)eponyms andHeaders:(NSArray *)sections;

- (void)assureEponymSelectedInListAnimated:(BOOL)animated;
- (void)assureSelectedEponymStarredInList;
- (void)assureEponymAtIndexPathStarredInList:(NSIndexPath *)indexPath;


@end