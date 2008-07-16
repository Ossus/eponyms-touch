//
//  eponyms_touchAppDelegate.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  Copyright home sweet home 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>


@class CategoriesViewController;
@class ListViewController;
@class EponymViewController;
@class Eponym;


@interface eponyms_touchAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	sqlite3 *database;
	
	// Eponyms
	NSInteger categoryShown;
	NSUInteger eponymShown;
	
	NSString *shownCategoryTitle;
	NSMutableArray *categoryArray;			// 1D	
	NSMutableArray *eponymArray;			// 2D!!	(for the table sections)
	NSMutableArray *eponymSectionArray;		// 1D	(holds the section titles - letters A..Z in our case)
	
	// View Controllers
	UINavigationController *navigationController;
	CategoriesViewController *categoriesController;
	ListViewController *listController;
	EponymViewController *eponymController;
	
	BOOL isUpdating;
}

@property (nonatomic, assign) NSInteger categoryShown;				// not unsigned since we will be using -1 for no category and 0 for all eponyms
@property (nonatomic, assign) NSUInteger eponymShown;

@property (nonatomic, retain) NSString *shownCategoryTitle;
@property (nonatomic, retain) NSMutableArray *categoryArray;
@property (nonatomic, retain) NSMutableArray *eponymArray;
@property (nonatomic, retain) NSMutableArray *eponymSectionArray;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;

@property (nonatomic, assign) BOOL isUpdating;


- (void) loadDatabaseAnimated:(BOOL) animated reload:(BOOL) as_reload;
- (void) loadEponymsOfCategory:(NSUInteger) category_id containingString:(NSString *) searchString animated:(BOOL) animated;
- (void) loadEponym:(Eponym *) eponym animated:(BOOL) animated;

- (NSString *) databaseFilePath;
- (NSDictionary *) databaseCreationQueries;


@end

