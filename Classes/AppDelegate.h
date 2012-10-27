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

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "EponymUpdaterDelegate.h"

@class EponymUpdater;
@class PPSplitViewController;
@class CategoriesViewController;
@class ListViewController;
@class EponymViewController;
@class InfoViewController;
@class EponymCategory;
@class Eponym;

typedef enum {
	EPLearningModeNone = 0,
	EPLearningModeNoTitle,
	EPLearningModeNoText
} EPLearningMode;


@interface AppDelegate : NSObject <UIApplicationDelegate, EponymUpdaterDelegate, UIAccelerometerDelegate> {
	
	// Accelerometer
	UIAccelerationValue accelerationX;
	UIAccelerationValue lastAccelerationX;
	UIAccelerationValue accelerationY;
	UIAccelerationValue lastAccelerationY;
	NSUInteger lastMainShakeAxis;					// 1 = X-axis, 2 = Y-axis
	NSTimeInterval randomIsRefractoryUntil;			// timestamp until the next shake event is allowed
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, assign) sqlite3 *database;

@property (nonatomic, assign) BOOL shouldAutoCheck;

@property (nonatomic, strong) EponymCategory *categoryShown;
@property (nonatomic, assign) NSInteger categoryIDShown;				// not unsigned! -100 = no category, -2 = recent, -1 = starred, 0 = all
@property (nonatomic, assign) NSUInteger eponymShown;

@property (nonatomic, strong) NSMutableArray *categoryArray;			// 2D
@property (nonatomic, strong) NSMutableArray *eponymArray;				// 2D!!	(for the table sections)
@property (nonatomic, strong) NSMutableArray *eponymSectionArray;		// 1D	(holds the section titles - letters A..Z in our case)
@property (nonatomic, strong) NSMutableArray *loadedEponyms;			// 1D, used if a memory warning occurs

@property (nonatomic, readonly, strong) PPSplitViewController *splitController;
@property (nonatomic, readonly, strong) UINavigationController *naviController;
@property (nonatomic, readonly, strong) CategoriesViewController *categoriesController;
@property (nonatomic, readonly, strong) ListViewController *listController;
@property (nonatomic, readonly, strong) EponymViewController *eponymController;
@property (nonatomic, readonly, strong) InfoViewController *infoController;

@property (nonatomic, strong) UIImage *starImageListActive;
@property (nonatomic, strong) UIImage *starImageEponymActive;
@property (nonatomic, strong) UIImage *starImageEponymInactive;

// Updating
@property (nonatomic, strong) EponymUpdater *myUpdater;
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
- (void) loadRandomEponymWithMode:(EPLearningMode)mode;
- (void) resetEponymRefractoryTimeout;

- (void) closeMainDatabase;
- (void) deleteDatabaseFile;

- (NSString *) databaseFilePath;
- (NSDictionary *) databaseCreationQueries;

- (EponymCategory *) categoryWithID:(NSInteger)identifier;

// Updating
- (void) checkForUpdates:(id)sender;
- (void) loadEponymXMLFromDisk;
- (void) abortUpdateAction;

- (UIColor *) naviBarTintColor;



@end

