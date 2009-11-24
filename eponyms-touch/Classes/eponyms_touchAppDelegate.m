//
//  eponyms_touchAppDelegate.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  AppDelegate for eponyms-touch
//  

#import "eponyms_touchAppDelegate.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "EponymUpdater.h"
#import "InfoViewController.h"
#import "CategoriesViewController.h"
#import "ListViewController.h"
#import "EponymViewController.h"
//#import <sqlite3_unicode.h>			// uncomment when building against iPhone OS 3.0+

#define EPONYM_TITLE_FIELD @"eponym_en"
#define EPONYM_TEXT_FIELD @"text_en"
#define THIS_DB_VERSION 1


static sqlite3_stmt *load_all_categories_query = nil;
static sqlite3_stmt *load_eponyms_query = nil;
static sqlite3_stmt *load_eponyms_search_query = nil;
static sqlite3_stmt *load_eponyms_of_category_query = nil;
static sqlite3_stmt *load_eponyms_of_category_search_query = nil;


@interface eponyms_touchAppDelegate ()

- (void) showNewEponymsAreAvailable:(BOOL)available;
- (void) loadEponymWithId:(NSUInteger)eponym_id animated:(BOOL)animated;
- (Eponym *) eponymWithId:(NSUInteger)eponym_id;
- (void) showInfoPanelAsFirstTimeLaunch:(BOOL)firstTimeLaunch;

@end


#pragma mark -

@implementation eponyms_touchAppDelegate

@synthesize window, database, myUpdater, usingEponymsOf;
@synthesize allowAutoRotate;
@synthesize allowLearnMode;
@synthesize shouldAutoCheck;
@synthesize iAmUpdating;
@synthesize didCheckForNewEponyms;
@synthesize newEponymsAvailable;
@dynamic categoryShown;
@synthesize naviController, categoriesController, listController, eponymController, infoController;
@synthesize categoryIDShown, eponymShown, categoryArray, eponymArray, eponymSectionArray, loadedEponyms;
@dynamic starImageListActive;
@dynamic starImageEponymActive;
@dynamic starImageEponymInactive;


- (void) applicationDidFinishLaunching:(UIApplication *)application
{
	// **** Prefs
	NSUInteger lastUsedDBVersion;
	NSInteger lastEponymCheck;
	NSInteger shownCategoryAtQuit;
	NSUInteger shownEponymAtQuit;
	CGFloat scrollPositionAtQuit;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *testValue = [defaults objectForKey:@"usingEponymsOf"];
	if (nil == testValue) {
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"lastEponymUpdate", nil];
		[defaults registerDefaults:appDefaults];
		
		self.usingEponymsOf = 0;
		self.shouldAutoCheck = YES;
		lastUsedDBVersion = THIS_DB_VERSION;
		lastEponymCheck = 0;
		shownCategoryAtQuit = -100;
		shownEponymAtQuit = 0;
		scrollPositionAtQuit = 0.0;
		self.allowAutoRotate = NO;
		self.allowLearnMode = YES;
	}
	
	// Prefs were there
	else {
		self.usingEponymsOf = [testValue intValue];
		self.shouldAutoCheck = [defaults boolForKey:@"shouldAutoCheck"];
		lastEponymCheck = [defaults integerForKey:@"lastEponymCheck"];
		lastUsedDBVersion = [defaults integerForKey:@"lastUsedDBVersion"];
		shownCategoryAtQuit = [defaults integerForKey:@"shownCategoryAtQuit"];
		shownEponymAtQuit = [defaults integerForKey:@"shownEponymAtQuit"];
		scrollPositionAtQuit = [defaults floatForKey:@"scrollPositionAtQuit"];
		self.allowAutoRotate = [defaults boolForKey:@"allowAutoRotate"];
		self.allowLearnMode = [defaults boolForKey:@"allowLearnMode"];
	}
	
	
	// **** GUI
	// create the NavigationController and the first ViewController (categoryController)
	self.categoriesController = [[[CategoriesViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[categoriesController setDelegate:self];
	self.naviController = [[[UINavigationController alloc] initWithRootViewController:categoriesController] autorelease];
	naviController.navigationBar.tintColor = [self naviBarTintColor];
	
	// create the view controllers for the Eponym list and the Eponym details
	self.listController = [[[ListViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[listController setDelegate:self];
	self.eponymController = [[[EponymViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[eponymController setDelegate:self];
	
	[window addSubview:[naviController view]];
	[window makeKeyAndVisible];
	
	// **** Data
	// If we updated from version 1.0.x, we must create a new one. We can delete the old one since no personal data was stored back then.
	if (lastUsedDBVersion < 1) {
		[self deleteDatabaseFile];
	}
	
	// connect to the database and load the categories
	BOOL databaseCreated = [self connectToDBAndCreateIfNeeded];		// returns a BOOL whether the database had to be created
	[self loadDatabaseAnimated:NO reload:NO];
	
	self.iAmUpdating = NO;
	self.newEponymsAvailable = NO;
	
	
	// **** Restore State
	if (shownEponymAtQuit > 0) {											// Eponym
		shownCategoryAtQuit = (shownCategoryAtQuit > -100) ? shownCategoryAtQuit : 0;
		[self loadEponymsOfCategoryID:shownCategoryAtQuit containingString:nil animated:NO];
		[self loadEponymWithId:shownEponymAtQuit animated:NO];
	}
	else if (shownCategoryAtQuit > -100) {									// Eponym list
		listController.atLaunchScrollTo = scrollPositionAtQuit;
		[self loadEponymsOfCategoryID:shownCategoryAtQuit containingString:nil animated:NO];
	}
	else {																	// Category list (may be infoView, but we don't want to go there)
		categoriesController.atLaunchScrollTo = scrollPositionAtQuit;
	}
	//NSLog(@"shownEponymAtQuit: %u, shownCategoryAtQuit: %u", shownEponymAtQuit, shownCategoryAtQuit);
	
	
	// **** Register for shake events
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
	accelerometer.updateInterval = 1 / 5;
	accelerometer.delegate = self;
	
	
	// **** First launch or older database structure - create from scratch
	if (databaseCreated || (usingEponymsOf < 1)) {
		[self showInfoPanelAsFirstTimeLaunch:YES];
	}
	
	// perform auto update check every week (if enabled)
	else if (shouldAutoCheck) {
		NSTimeInterval nowInEpoch = [[NSDate date] timeIntervalSince1970];
		if (nowInEpoch > (lastEponymCheck + 7 * 24 * 3600)) {
		//	NSLog(@"Will perform auto check (last check: %@)", [NSDate dateWithTimeIntervalSince1970:lastEponymCheck]);
			[self performSelector:@selector(checkForUpdates:) withObject:nil afterDelay:2.0];
		}
	}
}


- (void) dealloc
{
	self.categoryShown = nil;
	self.categoryArray = nil;
	self.eponymArray = nil;
	self.eponymSectionArray = nil;
	self.loadedEponyms = nil;
	
	self.naviController = nil;
	self.listController = nil;
	self.eponymController = nil;
	if (infoController) {
		self.infoController = nil;
	}
	
	if (myUpdater) {
		self.myUpdater = nil;
	}
	
	[window release];
	[super dealloc];
}


- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	// what we can do is aborting an eventually running import...
	if (myUpdater) {
		if (iAmUpdating) {
			[self abortUpdateAction];
		}
		self.myUpdater = nil;
	}
	
	// ...and unloading no longer displayed eponyms
	NSArray *loadedEponymsCopy = [loadedEponyms copy];
	for (Eponym *eponym in loadedEponymsCopy) {
		if (eponym.eponym_id != eponymShown) {
			[eponym unload];
		}
	}
	[loadedEponymsCopy release];
}


// save our currently displayed view and close the database
- (void) applicationWillTerminate:(UIApplication *)application
{
	[self closeMainDatabase];
	[UIAccelerometer sharedAccelerometer].delegate = nil;
	
	// Are we updating? Abort that
	if (iAmUpdating) {
		[self abortUpdateAction];
	}
	
	// Save state
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	CGRect bnds = [[[naviController topViewController] view] bounds];
	[defaults setInteger:THIS_DB_VERSION forKey:@"lastUsedDBVersion"];
	[defaults setBool:shouldAutoCheck forKey:@"shouldAutoCheck"];
	[defaults setInteger:categoryIDShown forKey:@"shownCategoryAtQuit"];
	[defaults setInteger:eponymShown forKey:@"shownEponymAtQuit"];
	[defaults setFloat:bnds.origin.y forKey:@"scrollPositionAtQuit"];
	[defaults setBool:allowAutoRotate forKey:@"allowAutoRotate"];
	[defaults setBool:allowLearnMode forKey:@"allowLearnMode"];
	[defaults synchronize];
}
#pragma mark -



#pragma mark KVC
- (EponymCategory *) categoryShown
{
	return categoryShown;
}
- (void) setCategoryShown:(EponymCategory *)catShown
{
	if (catShown != categoryShown) {
		[categoryShown release];
		categoryShown = [catShown retain];
	}
	
	categoryIDShown = catShown ? [catShown myID] : -100;
}

- (UIImage *) starImageListActive
{
	if (nil == starImageListActive) {
		self.starImageListActive = [UIImage imageNamed:@"Star_list_active.png"];
	}
	return starImageListActive;
}
- (void) setStarImageListActive:(UIImage *)newImage
{
	if (newImage != starImageListActive) {
		[starImageListActive release];
		starImageListActive = [newImage retain];
	}
}

- (UIImage *) starImageEponymActive
{
	if (nil == starImageEponymActive) {
		self.starImageEponymActive = [UIImage imageNamed:@"Star_eponym_active.png"];
	}
	return starImageEponymActive;
}
- (void) setStarImageEponymActive:(UIImage *)newImage
{
	if (newImage != starImageEponymActive) {
		[starImageEponymActive release];
		starImageEponymActive = [newImage retain];
	}
}

- (UIImage *) starImageEponymInactive
{
	if (nil == starImageEponymInactive) {
		self.starImageEponymInactive = [UIImage imageNamed:@"Star_eponym_inactive.png"];
	}
	return starImageEponymInactive;
}
- (void) setStarImageEponymInactive:(UIImage *)newImage
{
	if (newImage != starImageEponymInactive) {
		[starImageEponymInactive release];
		starImageEponymInactive = [newImage retain];
	}
}
#pragma mark -



#pragma mark Updating
- (void) checkForUpdates:(id)sender
{
	if (!myUpdater) {
		self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	}
	
	if (infoController) {
		myUpdater.viewController = infoController;
	}
	[myUpdater startUpdaterAction];
}

// called on first launch
- (void) loadEponymXMLFromDisk
{
	self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	myUpdater.updateAction = 3;
	if (infoController) {
		myUpdater.viewController = infoController;
	}
	
	[myUpdater startUpdaterAction];
}

- (void) abortUpdateAction
{
	if (myUpdater) {
		myUpdater.mustAbortImport = YES;
		self.iAmUpdating = NO;
	}
}

- (void) updaterDidStartAction:(EponymUpdater *)updater
{
	self.iAmUpdating = YES;
}

- (void) updater:(EponymUpdater *)updater didEndActionSuccessful:(BOOL)success
{
	[updater retain];
	self.iAmUpdating = NO;
	BOOL mayReleaseUpdater = NO;
	
	if (success) {
		NSTimeInterval nowInEpoch = [[NSDate date] timeIntervalSince1970];
		
		// did check for updates
		if (1 == updater.updateAction) {
			self.newEponymsAvailable = updater.newEponymsAvailable;
			[self showNewEponymsAreAvailable:updater.newEponymsAvailable];
			mayReleaseUpdater = !updater.newEponymsAvailable;
			
			if (!updater.newEponymsAvailable) {
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymCheck"];
			}
		}
		
		// did actually update eponyms
		else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if (updater.numEponymsParsed > 0) {
				self.usingEponymsOf = (NSInteger)[updater.eponymCreationDate timeIntervalSince1970];
				[defaults setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch]
														  forKey:@"lastEponymUpdate"];
				[defaults setObject:[NSNumber numberWithInt:usingEponymsOf]
														  forKey:@"usingEponymsOf"];
			}
			[defaults setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymCheck"];
			
			mayReleaseUpdater = !updater.parseFailed;
			[self showNewEponymsAreAvailable:NO];
			[self loadDatabaseAnimated:YES reload:YES];
		}
	}
	// else an error occurred, no need to do anything
	
	[updater release];
	if (mayReleaseUpdater) {
		self.myUpdater = nil;
	}
}

- (void) showNewEponymsAreAvailable:(BOOL)available
{
	[categoriesController showNewEponymsAvailable:available];
}
#pragma mark -



#pragma mark SQLite
// Creates a writable copy of the bundled default database in the application Documents directory.
- (BOOL) connectToDBAndCreateIfNeeded
{
	if (database) {
		return NO;
	}
	
	// needed to load the unicode extensions
	sqlite3_unicode_load();
	
	NSString *sqlPath = [self databaseFilePath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:sqlPath]) {
		if (SQLITE_OK != sqlite3_open([sqlPath UTF8String], &database)) {
			sqlite3_close(database);
			NSAssert1(0, @"Failed to open existing database: '%s'.", sqlite3_errmsg(database));
		}
		return NO;
	}
	
	// database does not exist - create it
	if ([fileManager createFileAtPath:sqlPath contents:nil attributes:nil]) {
		char *err;
		NSDictionary *creationQueries = [self databaseCreationQueries];
		NSString *createCatTable = [creationQueries objectForKey:@"createCatTable"];
		NSString *createLinkTable = [creationQueries objectForKey:@"createLinkTable"];
		NSString *createEpoTable = [creationQueries objectForKey:@"createEpoTable"];
		
		// Create the real database (still empty)
		if (SQLITE_OK == sqlite3_open([sqlPath UTF8String], &database)) {	// sqlite3_open_v2([sqlPath UTF8String], &database, SQLITE_OPEN_CREATE, NULL)
			sqlite3_exec(database, [createCatTable UTF8String], NULL, NULL, &err);
			if (err) {
				NSAssert1(0, @"Error: Failed to execute createCatTable: '%s'.", sqlite3_errmsg(database));
			}
			
			sqlite3_exec(database, [createLinkTable UTF8String], NULL, NULL, &err);
			if (err) {
				NSAssert1(0, @"Error: Failed to execute createLinkTable: '%s'.", sqlite3_errmsg(database));
			}
			
			sqlite3_exec(database, [createEpoTable UTF8String], NULL, NULL, &err);
			if (err) {
				NSAssert1(0, @"Error: Failed to execute createEpoTable: '%s'.", sqlite3_errmsg(database));
			}
			
		}
		else {
			sqlite3_close(database);
			NSAssert1(0, @"Failed to open new database: '%s'.", sqlite3_errmsg(database));
		}
	}
	else {
		NSAssert1(0, @"Error: Failed to touch the database file at '%@'.", sqlPath);
	}
	
	return YES;
}


- (void) loadDatabaseAnimated:(BOOL)animated reload:(BOOL)as_reload
{
	// Drop back to the root view
	[naviController popToRootViewControllerAnimated:animated];
	
	// empty eponyms and categories
	self.categoryArray = [NSMutableArray arrayWithCapacity:10];
	self.eponymArray = [NSMutableArray arrayWithCapacity:10];
	self.eponymSectionArray = [NSMutableArray arrayWithCapacity:10];
	self.loadedEponyms = [NSMutableArray array];
	
	if (as_reload) {
		self.categoryShown = nil;
		self.eponymShown = 0;
	}
	
	// Create EponymCategoryes for "All Eponyms", "Starred Eponyms" and "Recent Eponyms"
	EponymCategory *allEponyms =		[EponymCategory eponymCategoryWithID:0 tag:@"All" title:@"All Eponyms" whereStatement:@"1"];
	allEponyms.sqlOrderStatement = [NSString stringWithFormat:@"%@ COLLATE NOCASE ASC", EPONYM_TITLE_FIELD];
	
	EponymCategory *starredEponyms =	[EponymCategory eponymCategoryWithID:-1 tag:@"Starred" title:@"Starred Eponyms" whereStatement:@"starred = 1"];
	starredEponyms.hint = @"Double tap an eponym title in the list or the star top right in eponym view in order to star it";
	starredEponyms.sqlOrderStatement = [NSString stringWithFormat:@"%@ COLLATE NOCASE ASC", EPONYM_TITLE_FIELD];
	
	EponymCategory *recentEponyms =	[EponymCategory eponymCategoryWithID:-2 tag:@"Recent" title:@"Recent Eponyms" whereStatement:@"lastaccess > 0"];
	recentEponyms.hint = @"Seems you haven't yet read any eponym";
	recentEponyms.sqlOrderStatement = @"lastaccess DESC";
	recentEponyms.sqlLimitTo = 25;
	
	NSArray *specialCats = [NSArray arrayWithObjects:allEponyms, starredEponyms, recentEponyms, nil];
	[categoryArray addObject:specialCats];
	
	// Fetch the "real" categories
	NSMutableArray *normalCats = [NSMutableArray arrayWithCapacity:20];
	if (database) {
		
		// prepare the query
		if (load_all_categories_query == nil) {
			NSString *categoryTitle = @"category_en";
			const char *qry = [[NSString stringWithFormat:@"SELECT category_id, tag, %@ FROM categories ORDER BY %@, tag COLLATE NOCASE ASC", categoryTitle, categoryTitle] UTF8String];
			if (sqlite3_prepare_v2(database, qry, -1, &load_all_categories_query, NULL) != SQLITE_OK) {
				NSAssert1(0, @"Error: failed to prepare load_all_categories_query: '%s'.", sqlite3_errmsg(database));
			}
		}
		
		// Fetch categories
		while (sqlite3_step(load_all_categories_query) == SQLITE_ROW) {
			int cid = sqlite3_column_int(load_all_categories_query, 0);
			char *tag = (char *)sqlite3_column_text(load_all_categories_query, 1);
			char *title = (char *)sqlite3_column_text(load_all_categories_query, 2);
			
			EponymCategory *thisCategory = [[EponymCategory alloc] initWithID:cid
																		  tag:[NSString stringWithUTF8String:tag]
																		title:(title ? [NSString stringWithUTF8String:title] : @"")
															   whereStatement:nil];
			[normalCats addObject:thisCategory];
			[thisCategory release];
		}
		
		sqlite3_reset(load_all_categories_query);
	}
	[categoryArray addObject:normalCats];
	
	// GUI actions
	categoriesController.categoryArrayCache = categoryArray;
}


// *****
- (void) loadEponymsOfCurrentCategoryContainingString:(NSString *)searchString animated:(BOOL)animated;
{
	[self loadEponymsOfCategory:categoryShown containingString:searchString animated:animated];
}

// load eponyms of a given category (or all if category_id is ZERO)
- (void) loadEponymsOfCategoryID:(NSInteger)category_id containingString:(NSString *)searchString animated:(BOOL)animated
{
	EponymCategory *epoCat = [self categoryWithID:category_id];
	[self loadEponymsOfCategory:epoCat containingString:searchString animated:animated];
}

- (void) loadEponymsOfCategory:(EponymCategory *)category containingString:(NSString *)searchString animated:(BOOL)animated
{
	[eponymArray removeAllObjects];
	[eponymSectionArray removeAllObjects];
	[listController cacheEponyms:nil andHeaders:nil];
	
	if (NULL == database) {
		[self connectToDBAndCreateIfNeeded];
	}
	
	sqlite3_stmt *query;
	NSInteger category_id = [category myID];
	BOOL doSearch = (nil != searchString) && ![searchString isEqualToString:@""];
	
	// ***
	// compile query for the categories
	if (category_id > 0) {
		
		// search query
		if (doSearch) {
			if (!load_eponyms_of_category_search_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE (category_id = ? AND (%@ LIKE ? OR %@ LIKE ?)) ORDER BY %@ COLLATE NOCASE ASC",
								  EPONYM_TITLE_FIELD,
								  EPONYM_TITLE_FIELD,
								  EPONYM_TEXT_FIELD,
								  EPONYM_TITLE_FIELD ];
				
				if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_of_category_search_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_of_category_search_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_of_category_search_query;
			const char *search_chars = [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String];
			sqlite3_bind_text(query, 2, search_chars, -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(query, 3, search_chars, -1, SQLITE_TRANSIENT);
		}
		
		// standard query
		else {
			if (!load_eponyms_of_category_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE (category_id = ?) ORDER BY %@ COLLATE NOCASE ASC",
								 EPONYM_TITLE_FIELD,
								 EPONYM_TITLE_FIELD ];
				
				if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_of_category_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_of_category_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_of_category_query;
		}
		sqlite3_bind_int(query, 1, category_id);
	}
		
	// compile the queries for the special "categories" (all, starred and last accessed eponyms)
	else {
		if (category != categoryShown) {
			sqlite3_finalize(load_eponyms_query);			load_eponyms_query = NULL;
			sqlite3_finalize(load_eponyms_search_query);	load_eponyms_search_query = NULL;
		}
		
		// search query
		if (doSearch) {
			if (!load_eponyms_search_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM eponyms WHERE (%@ AND (%@ LIKE ? OR %@ LIKE ?)) ORDER BY %@ LIMIT ?",
								  EPONYM_TITLE_FIELD,
								  [category sqlWhereStatement],
								  EPONYM_TITLE_FIELD,
								  EPONYM_TEXT_FIELD,
								  [category sqlOrderStatement]];
				
				if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_search_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_search_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_search_query;
			sqlite3_bind_text(query, 1, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(query, 2, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_int(query, 3, [category sqlLimitTo]);
		}
		
		// standard query
		else {
			if (!load_eponyms_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM eponyms WHERE (%@) ORDER BY %@ LIMIT ?",
								 EPONYM_TITLE_FIELD,
								 [category sqlWhereStatement],
								 [category sqlOrderStatement]];
				
				if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_query;
			sqlite3_bind_int(query, 1, [category sqlLimitTo]);
		}
	}
	
	
	// ***
	// Fetch eponyms
	NSMutableString *title = [NSMutableString string];
	NSMutableString *oldFirstLetter = [NSMutableString string];
	NSMutableString *firstLetter = [NSMutableString string];
	NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
	
	while (sqlite3_step(query) == SQLITE_ROW) {
		int epo_id = sqlite3_column_int(query, 0);
		char *eponymTitle = (char *)sqlite3_column_text(query, 1);
		int starred = sqlite3_column_int(query, 2);
		
		[title setString:[NSString stringWithUTF8String:eponymTitle]];
		Eponym *eponym = [[Eponym alloc] initWithID:epo_id title:title delegate:self];
		eponym.starred = starred ? YES : NO;
		
		// determine the first letter and create the eponym (for all eponyms, starred eponyms or eponyms from the real categories)
		if (category_id >= -1) {
			[firstLetter setString:[title stringByPaddingToLength:1 withString:nil startingAtIndex:0]];
			
			// new first letter!
			if (NSOrderedSame != [firstLetter caseInsensitiveCompare:oldFirstLetter]) {
				if ([sectionArray count] > 0) {
					[eponymArray addObject:[[sectionArray copy] autorelease]];
					[sectionArray removeAllObjects];
					
					[eponymSectionArray addObject:[oldFirstLetter uppercaseString]];
				}
			}
			[oldFirstLetter setString:firstLetter];
		}
		
		// add to section array (there's only one section for the special categories)
		[sectionArray addObject:eponym];
		[eponym release];
	}
	
	// add last section
	if ([sectionArray count] > 0) {
		[eponymArray addObject:[[sectionArray copy] autorelease]];
		[eponymSectionArray addObject:[oldFirstLetter uppercaseString]];
	}
	[sectionArray release];
	
	sqlite3_reset(query);
	
	// GUI actions
	if (listController.atLaunchScrollTo == 0.0) {
		listController.atLaunchScrollTo = 0.1;										// will scroll the table to the top
	}
	[listController cacheEponyms:eponymArray andHeaders:eponymSectionArray];		// will also reload the table
	
	self.categoryShown = category;
	self.eponymShown = 0;
	if (listController != naviController.topViewController) {
		[naviController pushViewController:listController animated:animated];
	}
}


// *****
// load a single eponym
- (void) loadEponym:(Eponym *)eponym animated:(BOOL)animated
{
	[eponym load];
	
	eponymController.eponymToBeShown = eponym;
	eponymShown = eponym.eponym_id;
	if (eponymController != naviController.topViewController) {
		[naviController pushViewController:eponymController animated:animated];
	}
}

// accessory method to load the eponym last shown. Calls loadEponym:animated:
- (void) loadEponymWithId:(NSUInteger)eponym_id animated:(BOOL)animated
{
	Eponym *eponym = [self eponymWithId:eponym_id];
	[self loadEponym:eponym animated:animated];
}

// loads a random eponym of the current group
- (IBAction) loadRandomEponym:(id)sender
{
	NSTimeInterval startDate = [[NSDate date] timeIntervalSince1970];
	if (randomIsRefractoryUntil > startDate) {
		return;
	}
	randomIsRefractoryUntil = startDate + 3.0;		// at max all three seconds
	
	// no loaded group -> load all eponyms
	if (nil == eponymArray || [eponymArray count] < 1) {
		EponymCategory *fullCategory = [self categoryWithID:0];
		[self loadEponymsOfCategory:fullCategory containingString:nil animated:NO];
	}
	
	// get random group
	NSInteger randGroup = arc4random() % [eponymArray count];
	NSArray *groupItems = [eponymArray objectAtIndex:randGroup];
	
	// random eponym from group
	if (nil != groupItems && [groupItems count] > 0) {
		NSInteger randEpo = arc4random() % [groupItems count];
		Eponym *randEponym = [groupItems objectAtIndex:randEpo];
		
		// got one - load
		if (nil != randEponym) {
			eponymController.displayNextEponymInLearningMode = (2 == lastMainShakeAxis) ? -1 : 1;
			[self loadEponym:randEponym animated:YES];
		}
		
		// got none!
		else {
			NSLog(@"Did not get a random eponym!");
		}
	}
	
	// else invalid group!
	else {
		NSLog(@"Did not get a good random group! int: %i, max: %i", randGroup, [eponymArray count]);
	}
}


// cleans up the queries and closes the database
- (void) closeMainDatabase
{
	// finalize queries
	if (load_all_categories_query) {
		sqlite3_finalize(load_all_categories_query);
		load_all_categories_query = nil;
	}
	if (load_eponyms_query) {
		sqlite3_finalize(load_eponyms_query);
		load_eponyms_query = nil;
	}
	if (load_eponyms_search_query) {
		sqlite3_finalize(load_eponyms_search_query);
		load_eponyms_search_query = nil;
	}
	if (load_eponyms_of_category_query) {
		sqlite3_finalize(load_eponyms_of_category_query);
		load_eponyms_of_category_query = nil;
	}
	if (load_eponyms_of_category_search_query) {
		sqlite3_finalize(load_eponyms_of_category_search_query);
		load_eponyms_of_category_search_query = nil;
	}
	
	[Eponym finalizeQueries];
	
	// close
	if (database) {
		sqlite3_close(database);
		database = NULL;
	}
	
	sqlite3_unicode_free();
}

- (void) deleteDatabaseFile
{
	NSString *sqlPath = [self databaseFilePath];
	[[NSFileManager defaultManager] removeItemAtPath:sqlPath error:nil];
}
#pragma mark -



#pragma mark GUI Actions
- (void) showInfoPanel:(id) sender
{	
	[self showInfoPanelAsFirstTimeLaunch:NO];
}

- (void) showInfoPanelAsFirstTimeLaunch:(BOOL)firstTimeLaunch
{
	if (!infoController) {
		self.infoController = [[[InfoViewController alloc] initWithNibName:@"InfoView" bundle:nil] autorelease];
		infoController.delegate = self;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	infoController.lastEponymCheck = [defaults integerForKey:@"lastEponymCheck"];
	infoController.lastEponymUpdate = [defaults integerForKey:@"lastEponymUpdate"];
	infoController.firstTimeLaunch = firstTimeLaunch;
	
	UINavigationController *tempNaviController = [[UINavigationController alloc] initWithRootViewController:infoController];
	tempNaviController.navigationBar.tintColor = [self naviBarTintColor];
	[naviController presentModalViewController:tempNaviController animated:YES];
	[tempNaviController release];
}
#pragma mark -



#pragma mark Accelerometer Delegate
- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if (allowLearnMode) {
		BOOL deviceIsPortrait = UIDeviceOrientationIsPortrait(self.naviController.interfaceOrientation);
		UIAccelerationValue deviceX = deviceIsPortrait ? acceleration.x : acceleration.y;
		UIAccelerationValue deviceY = deviceIsPortrait ? acceleration.y : acceleration.x;
		
		// Simple high pass filter by subtracting low pass values
		accelerationX = deviceX - ((deviceX * 0.1) + (accelerationX * 0.9));
		accelerationY = deviceY - ((deviceY * 0.1) + (accelerationY * 0.9));
		
		// X-shake
		if ((lastAccelerationX * accelerationX < 0.0) && (abs(accelerationX - lastAccelerationX) > 1.5)) {
			lastMainShakeAxis = 1;
			[self loadRandomEponym:nil];
			accelerationX = 0.0;
		}
		
		// Y-shake
		else if ((lastAccelerationY * accelerationY < 0.0) && (abs(accelerationY - lastAccelerationY) > 1.2)) {
			lastMainShakeAxis = 2;
			[self loadRandomEponym:nil];
			accelerationY = 0.0;
		}
		
		// no shake at all
		else {
			lastMainShakeAxis = 0;
		}
		
		lastAccelerationX = accelerationX;
		lastAccelerationY = accelerationY;
	}
}
#pragma mark -



#pragma mark Utilities
- (EponymCategory *) categoryWithID:(NSInteger)identifier
{
	// categories with identifier > 0 are real categories and stored in the second subarray of categoryArray
	if (identifier > 0) {
		for (EponymCategory *epoCat in [categoryArray objectAtIndex:1]) {
			if (identifier == [epoCat myID]) {
				return epoCat;
			}
		}
	}
	
	// the other categories are "fake" categories (all, starred and recent eponyms) and are stored in the first subarray of categoryArray
	else {
		for (EponymCategory *epoCat in [categoryArray objectAtIndex:0]) {
			if (identifier == [epoCat myID]) {
				return epoCat;
			}
		}
	}
	
	return nil;
}

// might be expensive; will only be used after a relaunch and an eponym was shown (ok, not expensive. Takes 3ms on the simulator to find eponym 1623)
- (Eponym *) eponymWithId:(NSUInteger)eponym_id
{
	for (NSArray *sectionArr in eponymArray) {
		for (Eponym *eponym in sectionArr) {
			if (eponym.eponym_id == eponym_id) {
				return eponym;
			}
		}
	}
	
	return nil;
}


- (NSString *) databaseFilePath
{
	NSString *sqlFilename = @"eponyms.sqlite";
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *sqlPath = [documentsDirectory stringByAppendingPathComponent:sqlFilename];
	
	return sqlPath;
}


- (NSDictionary *) databaseCreationQueries
{
	NSDictionary *queries = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"CREATE TABLE IF NOT EXISTS categories (category_id INTEGER PRIMARY KEY, tag VARCHAR UNIQUE, category_en VARCHAR)", @"createCatTable",
							 @"CREATE TABLE IF NOT EXISTS category_eponym_linker (category_id INTEGER, eponym_id INTEGER)", @"createLinkTable",
							 @"CREATE TABLE IF NOT EXISTS eponyms (eponym_id INTEGER PRIMARY KEY, identifier VARCHAR UNIQUE, eponym_en VARCHAR, text_en TEXT, created INTEGER, lastedit INTEGER, lastaccess INTEGER, starred INTEGER DEFAULT 0)", @"createEpoTable", nil];
	
	return queries;
}

- (UIColor *) naviBarTintColor
{
	return [UIColor colorWithRed:0.0 green:0.25 blue:0.5 alpha:1.0];
}



@end
