//  
//  eponyms_touchAppDelegate.h
//  eponyms-touch
//  
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  AppDelegate Header for eponyms-touch
//  

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "EponymUpdaterDelegate.h"


@class EponymUpdater;
@class CategoriesViewController;
@class ListViewController;
@class EponymViewController;
@class InfoViewController;
@class EponymCategory;
@class Eponym;


@interface eponyms_touchAppDelegate : NSObject <UIApplicationDelegate, EponymUpdaterDelegate> {
	IBOutlet UIWindow *window;
	sqlite3 *database;
	
	// Prefs
	BOOL shouldAutoCheck;
	
	// Eponyms
	EponymCategory *categoryShown;
	NSInteger categoryIDShown;				// not unsigned! -100 = no category, -2 = recent, -1 = starred, 0 = all
	NSUInteger eponymShown;
	
	NSMutableArray *categoryArray;			// 2D	
	NSMutableArray *eponymArray;			// 2D!!	(for the table sections)
	NSMutableArray *eponymSectionArray;		// 1D	(holds the section titles - letters A..Z in our case)
	
	// View Controllers
	UINavigationController *navigationController;
	CategoriesViewController *categoriesController;
	ListViewController *listController;
	EponymViewController *eponymController;
	InfoViewController *infoController;
	
	// GUI
	UIImage *starImageListActive;
	UIImage *starImageEponymActive;
	UIImage *starImageEponymInactive;
	
	// Updating
	EponymUpdater *myUpdater;
	BOOL iAmUpdating;
	BOOL didCheckForNewEponyms;
	BOOL newEponymsAvailable;
	NSInteger usingEponymsOf;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, assign) sqlite3 *database;

@property (nonatomic, assign) BOOL shouldAutoCheck;

@property (nonatomic, retain) EponymCategory *categoryShown;
@property (nonatomic, assign) NSInteger categoryIDShown;
@property (nonatomic, assign) NSUInteger eponymShown;

@property (nonatomic, retain) NSMutableArray *categoryArray;
@property (nonatomic, retain) NSMutableArray *eponymArray;
@property (nonatomic, retain) NSMutableArray *eponymSectionArray;

@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) CategoriesViewController *categoriesController;
@property (nonatomic, retain) ListViewController *listController;
@property (nonatomic, retain) EponymViewController *eponymController;
@property (nonatomic, retain) InfoViewController *infoController;

@property (nonatomic, retain) UIImage *starImageListActive;
@property (nonatomic, retain) UIImage *starImageEponymActive;
@property (nonatomic, retain) UIImage *starImageEponymInactive;

// Updating
@property (nonatomic, retain) EponymUpdater *myUpdater;
@property (nonatomic, assign) BOOL iAmUpdating;
@property (nonatomic, assign) BOOL didCheckForNewEponyms;
@property (nonatomic, assign) BOOL newEponymsAvailable;
@property (nonatomic, assign) NSInteger usingEponymsOf;


- (BOOL) connectToDBAndCreateIfNeeded;
- (void) loadDatabaseAnimated:(BOOL)animated reload:(BOOL)as_reload;
- (void) loadEponymsOfCurrentCategoryContainingString:(NSString *)searchString animated:(BOOL)animated;
- (void) loadEponymsOfCategoryID:(NSInteger)category_id containingString:(NSString *)searchString animated:(BOOL)animated;
- (void) loadEponymsOfCategory:(EponymCategory *)category containingString:(NSString *)searchString animated:(BOOL)animated;
- (void) loadEponym:(Eponym *)eponym animated:(BOOL)animated;
- (void) closeMainDatabase;
- (void) deleteDatabaseFile;

- (NSString *) databaseFilePath;
- (NSDictionary *) databaseCreationQueries;

- (EponymCategory *) categoryWithID:(NSInteger)identifier;

// Updating
- (void) checkForUpdates:(id)sender;
- (void) loadEponymXMLFromDisk;
- (void) abortUpdateAction;




@end

