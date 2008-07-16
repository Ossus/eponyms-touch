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
#import "Eponym.h"
#import "InfoViewController.h"
#import "CategoriesViewController.h"
#import "ListViewController.h"
#import "EponymViewController.h"

#define EPONYM_TITLE_FIELD @"eponym_en"


//@interface eponyms_touchAppDelegate (Private)
//@end

static sqlite3_stmt *load_all_categories_query = nil;
static sqlite3_stmt *load_category_query = nil;
static sqlite3_stmt *load_category_query_with_search = nil;
static sqlite3_stmt *load_all_eponyms_query = nil;
static sqlite3_stmt *load_all_eponyms_query_with_search = nil;


@interface eponyms_touchAppDelegate (Private)

- (BOOL) createDatabaseIfNeeded;
- (void) loadEponymWithId:(NSUInteger) eponym_id animated:(BOOL) animated;
- (NSString *) categoryTitleForId:(NSUInteger) category_id;
- (Eponym *) eponymWithId:(NSUInteger) eponym_id;
- (void) showInfoPanelAsFirstTimeLaunch:(BOOL) firstTimeLaunch;

@end


@implementation eponyms_touchAppDelegate

@synthesize categoryShown, eponymShown;
@synthesize shownCategoryTitle, categoryArray, eponymArray, eponymSectionArray, window, navigationController;
@synthesize isUpdating;


- (void) applicationDidFinishLaunching:(UIApplication *) application
{
	// **** Prefs
	NSUInteger usingEponymsOf;
	NSInteger shownCategoryAtQuit;
	NSUInteger shownEponymAtQuit;
	CGFloat scrollPositionAtQuit;
	
	NSNumber *testValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"usingEponymsOf"];
	if(nil == testValue) {
		NSLog(@"standardUserDefaults not found!");
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:0], @"lastEponymCheck",
									 [NSNumber numberWithInt:0], @"lastEponymUpdate",
									 [NSNumber numberWithInt:0], @"usingEponymsOf",
									 [NSNumber numberWithInt:-1], @"shownCategoryAtQuit",
									 [NSNumber numberWithInt:0], @"shownEponymAtQuit",
									 [NSNumber numberWithFloat:0.0], @"scrollPositionAtQuit", nil];
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		usingEponymsOf = 0;
		shownCategoryAtQuit = -1;
		shownEponymAtQuit = 0;
		scrollPositionAtQuit = 0.0;
	}
	
	// Prefs were there
	else {
		shownCategoryAtQuit = [[NSUserDefaults standardUserDefaults] integerForKey:@"shownCategoryAtQuit"];
		shownEponymAtQuit = [[NSUserDefaults standardUserDefaults] integerForKey:@"shownEponymAtQuit"];
		scrollPositionAtQuit = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPositionAtQuit"];
	}
	
	
	// **** GUI
	// create the NavigationController and the first ViewController (categoryController)
	categoriesController = [[CategoriesViewController alloc] initWithNibName:nil bundle:nil];
	[categoriesController setDelegate:self];
	navigationController = [[UINavigationController alloc] initWithRootViewController:categoriesController];
	
	// create the view controllers for the Eponym list and the Eponym details
	listController = [[ListViewController alloc] initWithNibName:nil bundle:nil];
	[listController setDelegate:self];
	eponymController = [[EponymViewController alloc] initWithNibName:nil bundle:nil];
	[eponymController setDelegate:self];
	
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
	
	
	// **** Data
	// set up the database and load the categories
	BOOL databaseCreated = [self createDatabaseIfNeeded];		// createDatabaseIfNeeded returns a BOOL whether the database had to be created
	[self loadDatabaseAnimated:NO reload:NO];
	self.isUpdating = NO;
	
	
	// **** Restore State
	if(shownEponymAtQuit > 0) {														// Eponym
		[self loadEponymsOfCategory:shownCategoryAtQuit containingString:nil animated:NO];
		[self loadEponymWithId:shownEponymAtQuit animated:NO];
	}
	else if(shownCategoryAtQuit >= 0) {												// Eponym list
		listController.atLaunchScrollTo = scrollPositionAtQuit;
		[self loadEponymsOfCategory:shownCategoryAtQuit containingString:nil animated:NO];
	}
	else {																			// Category list (may be infoView, but we don't want to go there)
		categoriesController.atLaunchScrollTo = scrollPositionAtQuit;
	}
	//NSLog(@"shownEponymAtQuit: %u, shownCategoryAtQuit: %u", shownEponymAtQuit, shownCategoryAtQuit);
	
	
	// **** First launch
	if(databaseCreated || (usingEponymsOf < 1)) {
		[self showInfoPanelAsFirstTimeLaunch:YES];
	}
}


- (void) dealloc
{
	[shownCategoryTitle release];
	[categoryArray release];
	[eponymArray release];
	[eponymSectionArray release];
	
	[navigationController release];
	[listController release];
	[eponymController release];
	
	[window release];
	[super dealloc];
}


- (void) applicationDidReceiveMemoryWarning:(UIApplication *) application
{	
	// drop back to category selection (smallest memory footprint). Releases all eponyms
	[self loadDatabaseAnimated:YES reload:YES];
}


// save our currently displayed view and close the database
- (void) applicationWillTerminate:(UIApplication *) application
{
	// abort update
	if(isUpdating) {
		
	}
	
	// finalize queries
	if(load_all_categories_query) {
		sqlite3_finalize(load_all_categories_query);
	}
	if(load_category_query) {
		sqlite3_finalize(load_category_query);
	}
	if(load_category_query_with_search) {
		sqlite3_finalize(load_category_query_with_search);
	}
	if(load_all_eponyms_query) {
		sqlite3_finalize(load_all_eponyms_query);
	}
	if(load_all_eponyms_query_with_search) {
		sqlite3_finalize(load_all_eponyms_query_with_search);
	}
	
	[Eponym finalizeQueries];
	
	if(sqlite3_close(database) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to close database: '%s'.", sqlite3_errmsg(database));
	}
	
	// Save state
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	CGRect bnds = [[[navigationController topViewController] view] bounds];
	[defaults setObject:[NSNumber numberWithInt:categoryShown] forKey:@"shownCategoryAtQuit"];
	[defaults setObject:[NSNumber numberWithInt:eponymShown] forKey:@"shownEponymAtQuit"];
	[defaults setObject:[NSNumber numberWithFloat:bnds.origin.y] forKey:@"scrollPositionAtQuit"];
	[defaults synchronize];
}
#pragma mark -



#pragma mark SQLite
// Creates a writable copy of the bundled default database in the application Documents directory.
- (BOOL) createDatabaseIfNeeded
{
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
		if(SQLITE_OK == sqlite3_open([sqlPath UTF8String], &database)) {		// sqlite3_open_v2([sqlPath UTF8String], &database, SQLITE_OPEN_CREATE, NULL)
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


- (void) loadDatabaseAnimated:(BOOL) animated reload:(BOOL) as_reload
{
	// Drop back to the root view
	[navigationController popToRootViewControllerAnimated:animated];
	
	// empty eponyms and categories
	NSMutableArray *foo = [[NSMutableArray alloc] initWithCapacity:10];
	NSMutableArray *bar = [[NSMutableArray alloc] initWithCapacity:10];
	NSMutableArray *hat = [[NSMutableArray alloc] initWithCapacity:10];
	self.categoryArray = foo;
	self.eponymArray = bar;
	self.eponymSectionArray = hat;
	[foo release];
	[bar release];
	[hat release];
	
	if(as_reload) {
		categoryShown = -1;
		eponymShown = 0;
	}
	
	// Add "All Eponyms"
	[categoryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"id", @"All Eponyms", @"title", nil]];
	
	// check if the query exists
	if(load_all_categories_query == nil) {
		NSString *categoryName = @"category_en";
		const char *qry = [[NSString stringWithFormat:@"SELECT category_id, %@ FROM categories ORDER BY %@ COLLATE NOCASE", categoryName, categoryName] UTF8String];
		if(sqlite3_prepare_v2(database, qry, -1, &load_all_categories_query, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare load_all_categories_query: '%s'.", sqlite3_errmsg(database));
		}
	}
	
	// fetch categories
	while(sqlite3_step(load_all_categories_query) == SQLITE_ROW) {
		int cid = sqlite3_column_int(load_all_categories_query, 0);
		char *cat = (char *)sqlite3_column_text(load_all_categories_query, 1);
		
		NSDictionary *rowDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:cid], @"id", [NSString stringWithUTF8String:cat], @"title", nil];
		[categoryArray addObject:rowDict];
		[rowDict release];
	}
	
	sqlite3_reset(load_all_categories_query);
	
	// GUI actions
	categoriesController.categoryArrayCache = categoryArray;
}


// load eponyms of a given category (or all if category_id is ZERO)
- (void) loadEponymsOfCategory:(NSUInteger) category_id containingString:(NSString *) searchString animated:(BOOL) animated
{
	sqlite3_stmt *query;
	BOOL doSearch = ![searchString isEqualToString:@""] && (nil != searchString);
	
	[eponymArray removeAllObjects];
	[eponymSectionArray removeAllObjects];
	
	
	// restricted to a specific category
	if(category_id > 0) {
		
		// compile the query restricted to a category AND a searchstring
		if(doSearch) {
			if(load_category_query_with_search == nil) {
				const char *sql = [[NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@ FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE (category_id = ? AND %@ LIKE ?) ORDER BY %@ COLLATE NOCASE", EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD] UTF8String];
				
				if(sqlite3_prepare_v2(database, sql, -1, &load_category_query_with_search, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_category_query_with_search: '%s'.", sqlite3_errmsg(database));
				}
			}
			query = load_category_query_with_search;
			sqlite3_bind_text(query, 2, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		// compile the query restricted to a category
		else {
			if(load_category_query == nil) {
				const char *sql = [[NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@ FROM category_eponym_linker LEFT JOIN eponyms USING (eponym_id) WHERE category_id = ? ORDER BY %@ COLLATE NOCASE", EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD] UTF8String];
				
				if(sqlite3_prepare_v2(database, sql, -1, &load_category_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_category_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			query = load_category_query;
		}
		
		sqlite3_bind_int(query, 1, category_id);
	}
	
	
	// load eponyms of all categories
	else {

		// compile the query to search for a specific searchstring
		if(doSearch) {
			if(load_all_eponyms_query_with_search == nil) {
				const char *sql = [[NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@ FROM eponyms WHERE %@ LIKE ? ORDER BY %@ COLLATE NOCASE", EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD] UTF8String];
				
				if(sqlite3_prepare_v2(database, sql, -1, &load_all_eponyms_query_with_search, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_all_eponyms_query_with_search: '%s'.", sqlite3_errmsg(database));
				}
			}
			query = load_all_eponyms_query_with_search;
			sqlite3_bind_text(query, 1, [[NSString stringWithFormat:@"%%%@%%", searchString] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		// compile the query to load ALL eponyms
		else {
			if(load_all_eponyms_query == nil) {
				const char *sql = [[NSString stringWithFormat:@"SELECT eponyms.eponym_id, %@ FROM eponyms ORDER BY %@ COLLATE NOCASE", EPONYM_TITLE_FIELD, EPONYM_TITLE_FIELD] UTF8String];
				
				if(sqlite3_prepare_v2(database, sql, -1, &load_all_eponyms_query, NULL) != SQLITE_OK) {
					NSAssert1(0, @"Error: Failed to prepare load_all_eponyms_query: '%s'.", sqlite3_errmsg(database));
				}
			}
			query = load_all_eponyms_query;
		}
	}
	
	// Execute the query
	NSMutableString *title = [NSMutableString string];
	NSMutableString *oldFirstLetter = [NSMutableString string];
	NSMutableString *firstLetter = [NSMutableString string];
	NSMutableArray *sectionArray = [NSMutableArray array];
	
	// ***
	// Fetch eponyms
	while(sqlite3_step(query) == SQLITE_ROW) {
		int eid = sqlite3_column_int(query, 0);
		char *eponymTitle = (char *)sqlite3_column_text(query, 1);
		
		// determine the first letter and create the eponym
		[title setString:[NSString stringWithUTF8String:eponymTitle]];
		[firstLetter setString:[title stringByPaddingToLength:1 withString:nil startingAtIndex:0]];
		
		Eponym *eponym = [[Eponym alloc] initWithID:eid title:title fromDatabase:database];
		
		// new first letter!
		if(NSOrderedSame != [firstLetter caseInsensitiveCompare:oldFirstLetter]) {
			if([sectionArray count] > 0) {
				[eponymArray addObject:[sectionArray copy]];
				[eponymSectionArray addObject:[oldFirstLetter uppercaseString]];
				[sectionArray removeAllObjects];
			}
		}
		
		[sectionArray addObject:eponym];
		
		[eponym release];
		[oldFirstLetter setString:firstLetter];
	}
	
	// add last section
	[eponymArray addObject:[sectionArray copy]];
	[eponymSectionArray addObject:[oldFirstLetter uppercaseString]];
	self.shownCategoryTitle = [self categoryTitleForId:category_id];	
	
	sqlite3_reset(query);
	
	// GUI actions
	if(listController.atLaunchScrollTo == 0.0) {
		listController.atLaunchScrollTo = 0.1;										// will scroll the table to the top
	}
	[listController cacheEponyms:eponymArray andHeaders:eponymSectionArray];		// will also reload the table
	categoryShown = category_id;
	eponymShown = 0;
	if(listController != navigationController.topViewController) {
		[navigationController pushViewController:listController animated:animated];
	}
}


// load a single eponym
- (void) loadEponym:(Eponym *) eponym animated:(BOOL) animated
{
	[eponym load];
	eponymController.eponymToBeShown = eponym;
	eponymShown = eponym.eponym_id;
	[navigationController pushViewController:eponymController animated:animated];
}

// accessory method to load the eponym last shown. Calls loadEponym:animated:
- (void) loadEponymWithId:(NSUInteger) eponym_id animated:(BOOL) animated
{
	Eponym *eponym = [self eponymWithId:eponym_id];
	[self loadEponym:eponym animated:animated];
}
#pragma mark -



#pragma mark GUI Actions
- (void) showInfoPanel:(id) sender
{	
	[self showInfoPanelAsFirstTimeLaunch:NO];
}

- (void) showInfoPanelAsFirstTimeLaunch:(BOOL) firstTimeLaunch
{
	InfoViewController *infoController = [[InfoViewController alloc] initWithNibName:@"InfoView" bundle:nil];
	
	infoController.lastEponymCheck = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEponymCheck"];
	infoController.lastEponymUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEponymUpdate"];
	infoController.usingEponymsOf = [[NSUserDefaults standardUserDefaults] integerForKey:@"usingEponymsOf"];
	infoController.delegate = self;
	infoController.database = database;
	infoController.firstTimeLaunch = firstTimeLaunch;
	
	UINavigationController *tempNaviController = [[UINavigationController alloc] initWithRootViewController:infoController];
	[navigationController presentModalViewController:tempNaviController animated:YES];
	[tempNaviController release];
}
#pragma mark -



#pragma mark Utilities
- (NSString *) categoryTitleForId:(NSUInteger) category_id
{
	if(category_id > 0) {
		for(NSDictionary *catDict in categoryArray) {
			if(category_id == [[catDict objectForKey:@"id"] intValue]) {
				return [catDict objectForKey:@"title"];
			}
		}
	}
	
	return @"Eponyms";
}

// might be expensive; will only be used after a relaunch and an eponym was shown (ok, not expensive. Takes 3ms on the simulator to find eponym 1623)
- (Eponym *) eponymWithId:(NSUInteger) eponym_id
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
							 @"CREATE TABLE categories (category_id INTEGER PRIMARY KEY, category_en VARCHAR)", @"createCatTable",
							 @"CREATE TABLE category_eponym_linker (category_id INTEGER, eponym_id INTEGER)", @"createLinkTable",
							 @"CREATE TABLE eponyms (eponym_id INTEGER PRIMARY KEY, eponym_en, VARCHAR, text TEXT, created REAL, lastedit REAL)", @"createEpoTable", nil];
	
	return queries;
}



@end
