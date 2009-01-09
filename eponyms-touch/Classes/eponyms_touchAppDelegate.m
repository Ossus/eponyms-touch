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

#define EPONYM_TITLE_FIELD @"eponym_en"
#define EPONYM_TEXT_FIELD @"text_en"
#define THIS_DB_VERSION 1


//@interface eponyms_touchAppDelegate (Private)
//@end

static sqlite3_stmt *load_all_categories_query = nil;
static sqlite3_stmt *load_eponyms_query = nil;
static sqlite3_stmt *load_eponyms_search_query = nil;
static sqlite3_stmt *load_eponyms_of_category_query = nil;
static sqlite3_stmt *load_eponyms_of_category_search_query = nil;


@interface eponyms_touchAppDelegate (Private)

- (void) showNewEponymsAreAvailable:(BOOL)available;
- (void) loadEponymWithId:(NSUInteger)eponym_id animated:(BOOL)animated;
- (Eponym *) eponymWithId:(NSUInteger)eponym_id;
- (void) showInfoPanelAsFirstTimeLaunch:(BOOL)firstTimeLaunch;

@end


#pragma mark -

@implementation eponyms_touchAppDelegate

@synthesize window, database, myUpdater, usingEponymsOf, shouldAutoCheck, iAmUpdating, didCheckForNewEponyms, newEponymsAvailable;
@dynamic categoryShown;
@synthesize navigationController, categoriesController, listController, eponymController, infoController;
@synthesize categoryIDShown, eponymShown, categoryArray, eponymArray, eponymSectionArray, loadedEponyms, starImageListActive, starImageEponymActive, starImageEponymInactive;


- (void) applicationDidFinishLaunching:(UIApplication *)application
{
//	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	
	// **** Prefs
	NSUInteger lastUsedDBVersion;
	NSInteger lastEponymCheck;
	NSInteger shownCategoryAtQuit;
	NSUInteger shownEponymAtQuit;
	CGFloat scrollPositionAtQuit;
	
	NSNumber *testValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"usingEponymsOf"];
	if(nil == testValue) {
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"lastEponymUpdate", nil];
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		
		self.usingEponymsOf = 0;
		self.shouldAutoCheck = NO;
		lastUsedDBVersion = THIS_DB_VERSION;
		lastEponymCheck = 0;
		shownCategoryAtQuit = -100;
		shownEponymAtQuit = 0;
		scrollPositionAtQuit = 0.0;
	}
	
	// Prefs were there
	else {
		self.usingEponymsOf = [testValue intValue];
		self.shouldAutoCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutoCheck"];
		lastEponymCheck = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEponymCheck"];
		lastUsedDBVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastUsedDBVersion"];
		shownCategoryAtQuit = [[NSUserDefaults standardUserDefaults] integerForKey:@"shownCategoryAtQuit"];
		shownEponymAtQuit = [[NSUserDefaults standardUserDefaults] integerForKey:@"shownEponymAtQuit"];
		scrollPositionAtQuit = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPositionAtQuit"];
	}
	
	
	// **** GUI
	// create the NavigationController and the first ViewController (categoryController)
	self.categoriesController = [[[CategoriesViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[categoriesController setDelegate:self];
	self.navigationController = [[[UINavigationController alloc] initWithRootViewController:categoriesController] autorelease];
//	navigationController.navigationBar.tintColor = [self naviBarTintColor];
	
	// create the view controllers for the Eponym list and the Eponym details
	self.listController = [[[ListViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[listController setDelegate:self];
	self.eponymController = [[[EponymViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[eponymController setDelegate:self];
	
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
	
	self.starImageListActive = [UIImage imageNamed:@"Star_list_active.png"];
	self.starImageEponymActive = [UIImage imageNamed:@"Star_eponym_active.png"];
	self.starImageEponymInactive = [UIImage imageNamed:@"Star_eponym_inactive.png"];
	
	
	// **** Data
	// If we updated from version 1.0.x, we must create a new one. We can delete the old one since no personal data was stored back then.
	if(lastUsedDBVersion < 1) {
		[self deleteDatabaseFile];
	}
	
	// connect to the database and load the categories
	BOOL databaseCreated = [self connectToDBAndCreateIfNeeded];		// returns a BOOL whether the database had to be created
	[self loadDatabaseAnimated:NO reload:NO];
	
	self.iAmUpdating = NO;
	self.newEponymsAvailable = NO;
	
	
	// **** Restore State
	if(shownEponymAtQuit > 0) {														// Eponym
		[self loadEponymsOfCategoryID:shownCategoryAtQuit containingString:nil animated:NO];
		[self loadEponymWithId:shownEponymAtQuit animated:NO];
	}
	else if(shownCategoryAtQuit > -100) {												// Eponym list
		listController.atLaunchScrollTo = scrollPositionAtQuit;
		[self loadEponymsOfCategoryID:shownCategoryAtQuit containingString:nil animated:NO];
	}
	else {																			// Category list (may be infoView, but we don't want to go there)
		categoriesController.atLaunchScrollTo = scrollPositionAtQuit;
	}
	//NSLog(@"shownEponymAtQuit: %u, shownCategoryAtQuit: %u", shownEponymAtQuit, shownCategoryAtQuit);
	
	
	// **** First launch or older database structure - create from scratch
	if(databaseCreated || (usingEponymsOf < 1)) {
		[self showInfoPanelAsFirstTimeLaunch:YES];
	}
	
	// perform auto update check every week (if enabled)
	else if(shouldAutoCheck) {
		NSTimeInterval nowInEpoch = [[NSDate date] timeIntervalSince1970];
		if(nowInEpoch > (lastEponymCheck + 7 * 24 * 3600)) {
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
	
	self.navigationController = nil;
	self.listController = nil;
	self.eponymController = nil;
	if(infoController) {
		self.infoController = nil;
	}
	
	if(myUpdater) {
		self.myUpdater = nil;
	}
	
	[window release];
	[super dealloc];
}


- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	// what we can do is aborting an eventually running import...
	if(myUpdater) {
		if(iAmUpdating) {
			[self abortUpdateAction];
		}
		self.myUpdater = nil;
	}
	
	// ...and unloading no longer displayed eponyms
	NSArray *loadedEponymsCopy = [loadedEponyms copy];
	for(Eponym *eponym in loadedEponymsCopy) {
		if(eponym.eponym_id != eponymShown) {
			[eponym unload];
		}
	}
	[loadedEponymsCopy release];
}


// save our currently displayed view and close the database
- (void) applicationWillTerminate:(UIApplication *)application
{
	[self closeMainDatabase];
	
	// Are we updating? Abort that
	if(iAmUpdating) {
		[self abortUpdateAction];
	}
	
	// Save state
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	CGRect bnds = [[[navigationController topViewController] view] bounds];
	[defaults setInteger:THIS_DB_VERSION forKey:@"lastUsedDBVersion"];
	[defaults setBool:shouldAutoCheck forKey:@"shouldAutoCheck"];
	[defaults setInteger:categoryIDShown forKey:@"shownCategoryAtQuit"];
	[defaults setInteger:eponymShown forKey:@"shownEponymAtQuit"];
	[defaults setFloat:bnds.origin.y forKey:@"scrollPositionAtQuit"];
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
	if(catShown != categoryShown) {
		[categoryShown release];
		categoryShown = [catShown retain];
	}
	
	categoryIDShown = catShown ? [catShown myID] : -100;
}
#pragma mark -



#pragma mark Updating
- (void) checkForUpdates:(id)sender
{
	if(!myUpdater) {
		self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	}
	
	if(infoController) {
		myUpdater.viewController = infoController;
	}
	[myUpdater startUpdaterAction];
}

// called on first launch
- (void) loadEponymXMLFromDisk
{
	self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	myUpdater.updateAction = 3;
	if(infoController) {
		myUpdater.viewController = infoController;
	}
	
	[myUpdater startUpdaterAction];
}

- (void) abortUpdateAction
{
	if(myUpdater) {
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
	
	if(success) {
		NSTimeInterval nowInEpoch = [[NSDate date] timeIntervalSince1970];
		
		// did check for updates
		if(1 == updater.updateAction) {
			self.newEponymsAvailable = updater.newEponymsAvailable;
			[self showNewEponymsAreAvailable:updater.newEponymsAvailable];
			mayReleaseUpdater = !updater.newEponymsAvailable;
			
			if(!updater.newEponymsAvailable) {
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymCheck"];
			}
		}
		
		// did actually update eponyms
		else {
			if(updater.numEponymsParsed > 0) {
				self.usingEponymsOf = (NSInteger)[updater.eponymCreationDate timeIntervalSince1970];
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch]
														  forKey:@"lastEponymUpdate"];
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:usingEponymsOf]
														  forKey:@"usingEponymsOf"];
			}
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymCheck"];
			
			mayReleaseUpdater = !updater.parseFailed;
			[self showNewEponymsAreAvailable:NO];
			[self loadDatabaseAnimated:YES reload:YES];
		}
	}
	// else an error occurred, no need to do anything
	
	[updater release];
	if(mayReleaseUpdater) {
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
	if(database) {
		return NO;
	}
	
	NSString *sqlPath = [self databaseFilePath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if([fileManager fileExistsAtPath:sqlPath]) {
		if(SQLITE_OK != sqlite3_open([sqlPath UTF8String], &database)) {
			sqlite3_close(database);
			NSAssert1(0, @"Failed to open existing database: '%s'.", sqlite3_errmsg(database));
		}
		return NO;
	}
	
	// database does not exist - create it
	if([fileManager createFileAtPath:sqlPath contents:nil attributes:nil]) {
		char *err;
		NSDictionary *creationQueries = [self databaseCreationQueries];
		NSString *createCatTable = [creationQueries objectForKey:@"createCatTable"];
		NSString *createLinkTable = [creationQueries objectForKey:@"createLinkTable"];
		NSString *createEpoTable = [creationQueries objectForKey:@"createEpoTable"];
		
		// Create the real database (still empty)
		if(SQLITE_OK == sqlite3_open([sqlPath UTF8String], &database)) {	// sqlite3_open_v2([sqlPath UTF8String], &database, SQLITE_OPEN_CREATE, NULL)
			sqlite3_exec(database, [createCatTable UTF8String], NULL, NULL, &err);
			if(err) {
				NSAssert1(0, @"Error: Failed to execute createCatTable: '%s'.", sqlite3_errmsg(database));
			}
			
			sqlite3_exec(database, [createLinkTable UTF8String], NULL, NULL, &err);
			if(err) {
				NSAssert1(0, @"Error: Failed to execute createLinkTable: '%s'.", sqlite3_errmsg(database));
			}
			
			sqlite3_exec(database, [createEpoTable UTF8String], NULL, NULL, &err);
			if(err) {
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
	[navigationController popToRootViewControllerAnimated:animated];
	
	// empty eponyms and categories
	self.categoryArray = [NSMutableArray arrayWithCapacity:10];
	self.eponymArray = [NSMutableArray arrayWithCapacity:10];
	self.eponymSectionArray = [NSMutableArray arrayWithCapacity:10];
	self.loadedEponyms = [NSMutableArray array];
	
	if(as_reload) {
		self.categoryShown = nil;
		self.eponymShown = 0;
	}
	
	// Create EponymCategoryes for "All Eponyms", "Starred Eponyms" and "Recent Eponyms"
	EponymCategory *allEponyms =		[EponymCategory eponymCategoryWithID:0 tag:@"All" title:@"All Eponyms" whereStatement:@"1"];
	allEponyms.sqlOrderStatement = [NSString stringWithFormat:@"%@ COLLATE NOCASE ASC", EPONYM_TITLE_FIELD];
	
	EponymCategory *starredEponyms =	[EponymCategory eponymCategoryWithID:-1 tag:@"Starred" title:@"Starred Eponyms" whereStatement:@"starred = 1"];
	starredEponyms.hint = @"Double tap an eponym title in order to star it";
	starredEponyms.sqlOrderStatement = [NSString stringWithFormat:@"%@ COLLATE NOCASE ASC", EPONYM_TITLE_FIELD];
	
	EponymCategory *recentEponyms =	[EponymCategory eponymCategoryWithID:-2 tag:@"Recent" title:@"Recent Eponyms" whereStatement:@"lastaccess > 0"];
	recentEponyms.hint = @"Seems you haven't yet read any eponym";
	recentEponyms.sqlOrderStatement = @"lastaccess DESC";
	recentEponyms.sqlLimitTo = 25;
	
	NSArray *specialCats = [NSArray arrayWithObjects:allEponyms, starredEponyms, recentEponyms, nil];
	[categoryArray addObject:specialCats];
	
	// Fetch the "real" categories
	NSMutableArray *normalCats = [NSMutableArray arrayWithCapacity:20];
	if(database) {
		
		// prepare the query
		if(load_all_categories_query == nil) {
			NSString *categoryTitle = @"category_en";
			const char *qry = [[NSString stringWithFormat:@"SELECT category_id, tag, %@ FROM categories ORDER BY %@, tag COLLATE NOCASE ASC", categoryTitle, categoryTitle] UTF8String];
			if(sqlite3_prepare_v2(database, qry, -1, &load_all_categories_query, NULL) != SQLITE_OK) {
				NSAssert1(0, @"Error: failed to prepare load_all_categories_query: '%s'.", sqlite3_errmsg(database));
			}
		}
		
		// Fetch categories
		while(sqlite3_step(load_all_categories_query) == SQLITE_ROW) {
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
	NSLog(@"load eponyms of cat %@", category);
	[eponymArray removeAllObjects];
	[eponymSectionArray removeAllObjects];
	[listController cacheEponyms:nil andHeaders:nil];
	
	if(nil == database) {
		[self connectToDBAndCreateIfNeeded];
	}
	
	sqlite3_stmt *query;
	NSInteger category_id = [category myID];
	BOOL doSearch = (nil != searchString) && ![searchString isEqualToString:@""];
	
	// ***
	// compile query for the categories
	if(category_id > 0) {
		
		// search query
		if(doSearch) {
			if(!load_eponyms_of_category_search_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE (category_id = ? AND (%@ LIKE ? OR %@ LIKE ?)) ORDER BY %@ COLLATE NOCASE ASC",
								  EPONYM_TITLE_FIELD,
								  EPONYM_TITLE_FIELD,
								  EPONYM_TEXT_FIELD,
								  EPONYM_TITLE_FIELD ];
				
				if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_of_category_search_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_of_category_search_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_of_category_search_query;
			sqlite3_bind_text(query, 2, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(query, 3, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		// standard query
		else {
			if(!load_eponyms_of_category_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE (category_id = ?) ORDER BY %@ COLLATE NOCASE ASC",
								 EPONYM_TITLE_FIELD,
								 EPONYM_TITLE_FIELD ];
				
				if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_of_category_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_eponyms_of_category_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			
			query = load_eponyms_of_category_query;
		}
		sqlite3_bind_int(query, 1, category_id);
	}
		
	// compile the queries for the special "categories" (all, starred and last accessed eponyms)
	else {
		if(category != categoryShown) {
			sqlite3_finalize(load_eponyms_query);			load_eponyms_query = nil;
			sqlite3_finalize(load_eponyms_search_query);	load_eponyms_search_query = nil;
		}
		
		// search query
		if(doSearch) {
			if(!load_eponyms_search_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM eponyms WHERE (%@ AND (%@ LIKE ? OR %@ LIKE ?)) ORDER BY %@ LIMIT ?",
								  EPONYM_TITLE_FIELD,
								  [category sqlWhereStatement],
								  EPONYM_TITLE_FIELD,
								  EPONYM_TEXT_FIELD,
								  [category sqlOrderStatement]];
				
				if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_search_query, NULL) != SQLITE_OK) {
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
			if(!load_eponyms_query) {
				NSString *sql = [NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@, eponyms.starred FROM eponyms WHERE (%@) ORDER BY %@ LIMIT ?",
								 EPONYM_TITLE_FIELD,
								 [category sqlWhereStatement],
								 [category sqlOrderStatement]];
				
				if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &load_eponyms_query, NULL) != SQLITE_OK) {
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
	
	while(sqlite3_step(query) == SQLITE_ROW) {
		int eid = sqlite3_column_int(query, 0);
		char *eponymTitle = (char *)sqlite3_column_text(query, 1);
		int starred = sqlite3_column_int(query, 2);
		
		[title setString:[NSString stringWithUTF8String:eponymTitle]];
		Eponym *eponym = [[Eponym alloc] initWithID:eid title:title delegate:self];
		eponym.starred = starred ? YES : NO;
		
		// determine the first letter and create the eponym (for all eponyms, starred eponyms or eponyms from the real categories)
		if(category_id >= -1) {
			[firstLetter setString:[title stringByPaddingToLength:1 withString:nil startingAtIndex:0]];
			
			// new first letter!
			if(NSOrderedSame != [firstLetter caseInsensitiveCompare:oldFirstLetter]) {
				if([sectionArray count] > 0) {
					[eponymArray addObject:sectionArray];
					[sectionArray release];
					sectionArray = [[NSMutableArray alloc] init];
					
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
	if([sectionArray count] > 0) {
		[eponymArray addObject:sectionArray];
		[eponymSectionArray addObject:[oldFirstLetter uppercaseString]];
	}
	[sectionArray release];
	
	sqlite3_reset(query);
	
	// GUI actions
	if(listController.atLaunchScrollTo == 0.0) {
		listController.atLaunchScrollTo = 0.1;										// will scroll the table to the top
	}
	[listController cacheEponyms:eponymArray andHeaders:eponymSectionArray];		// will also reload the table
	
	self.categoryShown = category;
	self.eponymShown = 0;
	if(listController != navigationController.topViewController) {
		[navigationController pushViewController:listController animated:animated];
	}
}


// *****
// load a single eponym
- (void) loadEponym:(Eponym *)eponym animated:(BOOL)animated
{
	[eponym load];
	
	eponymController.eponymToBeShown = eponym;
	eponymShown = eponym.eponym_id;
	[navigationController pushViewController:eponymController animated:animated];
}

// accessory method to load the eponym last shown. Calls loadEponym:animated:
- (void) loadEponymWithId:(NSUInteger)eponym_id animated:(BOOL)animated
{
	Eponym *eponym = [self eponymWithId:eponym_id];
	[self loadEponym:eponym animated:animated];
}


// cleans up the queries and closes the database
- (void) closeMainDatabase
{
	// finalize queries
	if(load_all_categories_query) {
		sqlite3_finalize(load_all_categories_query);
		load_all_categories_query = nil;
	}
	if(load_eponyms_query) {
		sqlite3_finalize(load_eponyms_query);
		load_eponyms_query = nil;
	}
	if(load_eponyms_search_query) {
		sqlite3_finalize(load_eponyms_search_query);
		load_eponyms_search_query = nil;
	}
	if(load_eponyms_of_category_query) {
		sqlite3_finalize(load_eponyms_of_category_query);
		load_eponyms_of_category_query = nil;
	}
	if(load_eponyms_of_category_search_query) {
		sqlite3_finalize(load_eponyms_of_category_search_query);
		load_eponyms_of_category_search_query = nil;
	}
	
	[Eponym finalizeQueries];
	
	// close
	if(database) {
		sqlite3_close(database);
		database = nil;
	}
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
	if(!infoController) {
		self.infoController = [[[InfoViewController alloc] initWithNibName:@"InfoView" bundle:nil] autorelease];
		infoController.delegate = self;
	}
	
	infoController.lastEponymCheck = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEponymCheck"];
	infoController.lastEponymUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEponymUpdate"];
	infoController.firstTimeLaunch = firstTimeLaunch;
	
	UINavigationController *tempNaviController = [[UINavigationController alloc] initWithRootViewController:infoController];
	[navigationController presentModalViewController:tempNaviController animated:YES];
//	tempNaviController.navigationBar.tintColor = [self naviBarTintColor];
	[tempNaviController release];
}
#pragma mark -



#pragma mark Utilities
- (EponymCategory *) categoryWithID:(NSInteger)identifier
{
	// categories with identifier > 0 are real categories and stored in the second subarray of categoryArray
	if(identifier > 0) {
		for(EponymCategory *epoCat in [categoryArray objectAtIndex:1]) {
			if(identifier == [epoCat myID]) {
				return epoCat;
			}
		}
	}
	
	// the other categories are "fake" categories (all, starred and recent eponyms) and are stored in the first subarray of categoryArray
	else {
		for(EponymCategory *epoCat in [categoryArray objectAtIndex:0]) {
			if(identifier == [epoCat myID]) {
				return epoCat;
			}
		}
	}
	
	return nil;
}

// might be expensive; will only be used after a relaunch and an eponym was shown (ok, not expensive. Takes 3ms on the simulator to find eponym 1623)
- (Eponym *) eponymWithId:(NSUInteger)eponym_id
{
	for(NSArray *sectionArr in eponymArray) {
		for(Eponym *eponym in sectionArr) {
			if(eponym.eponym_id == eponym_id) {
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
	return nil;	//[UIColor colorWithRed:0.1 green:0.22 blue:0.55 alpha:1.0];
}



@end
