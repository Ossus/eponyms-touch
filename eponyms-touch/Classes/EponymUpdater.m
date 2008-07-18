//
//  EponymUpdater.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 08.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Updater object that downloads the eponym XML and fills the SQLite database
//  for eponyms-touch
//  


#import "EponymUpdater.h"
#import "InfoViewController.h"
#import "eponyms_touchAppDelegate.h"



@interface EponymUpdater (Private)

// Download delegate
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (void) downloadFailedWithMessage:(NSString *)message;

// Main functions
- (void) parseEponyms:(NSData *)XMLData;
- (void) parseNewEponymCheck:(NSData *)XMLData;

// Parser delegate
- (void) parserDidStartDocument:(NSXMLParser *)parser;
- (void) parseXMLData:(NSData *)data parseError:(NSError **) error;
- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void) updateProgress:(NSNumber *)progress;

// SQLite
- (void) emptyDBAndPrepareQueries;
- (void) catMemoryDBToDisk;
- (void) createInMemoryDatabase;
- (void) finalizeQueries;
- (void) insertEponymIntoDatabase:(NSDictionary *)eponymDict withCategories:(NSArray *)categoryArray;
- (NSInteger) epochForStringDate:(NSString *)stringDate;

@end

#pragma mark -



#pragma mark SQLite statics

static sqlite3_stmt *insert_eponym_query = nil;
static sqlite3_stmt *insert_category_query = nil;
static sqlite3_stmt *insert_linker_query = nil;

#pragma mark -


@implementation EponymUpdater

@synthesize delegate, appDelegate, updateAction, mustAbortImport;
@synthesize statusCode, expectedContentLength, myConnection, receivedData;
@synthesize eponymCheckLastUpdateTime, eponymCheckFileSize, eponymCheckNumEponyms;
@synthesize readyToLoadNumEponyms, eponymCreationDate, currentlyParsedEponym, contentOfCurrentXMLNode, categoriesOfCurrentEponym, categoriesAlreadyInserted, numEponymsParsed;



- (id) initWithDelegate:(id) myDelegate
{
	self = [super init];
	if(self) {
		self.delegate = myDelegate;
		self.appDelegate = [[UIApplication sharedApplication] delegate];
		self.receivedData = [NSMutableData data];
		self.mustAbortImport = NO;
		self.categoriesAlreadyInserted = [[[NSMutableDictionary alloc] init] autorelease];
		
		[delegate setIAmUpdating:YES];
	}
	
	return self;
}


- (void) dealloc
{
	[delegate release];							delegate = nil;
	[appDelegate release];						appDelegate = nil;
	[receivedData release];						receivedData = nil;
	
	[eponymCreationDate release];				eponymCreationDate = nil;
	[currentlyParsedEponym release];			currentlyParsedEponym = nil;
	[contentOfCurrentXMLNode release];			contentOfCurrentXMLNode = nil;
	[categoriesOfCurrentEponym release];		categoriesOfCurrentEponym = nil;
	[categoriesAlreadyInserted release];		categoriesAlreadyInserted = nil;
	
	// SQLite
	[self finalizeQueries];
	
	[super dealloc];
}
#pragma mark -



#pragma mark Downloading
- (void) startDownloadingWithAction:(NSUInteger) myAction
{
	self.updateAction = myAction;
	[delegate setStatusMessage:@"Downloading..."];
	[delegate setProgress:0.0];
	
	// check desired action: 1 = check for updates, 2 = download and install eponyms
	NSURL *url;
	if(2 == updateAction) {
		url = [delegate eponymXMLURL];
	}
	else {
		url = [delegate eponymUpdateCheckURL];
	}
	
	// create the request and start downloading by making the connection
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	self.myConnection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
	
	if(!myConnection) {
		[self downloadFailedWithMessage:@"Could not create the NSURLConnection object"];
	}
}

// called right before we send a request
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	NSURLRequest *newRequest = request;
	
	// Should implement this in case we receive a redirect
	if(redirectResponse) {
		newRequest = nil;
		
		[myConnection release];
		[self downloadFailedWithMessage:@"Server sent a redirect response I don't understand"];
	}
	return newRequest;
}

// called whenever we receive a response from the server following our request
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[receivedData setLength:0];
	self.expectedContentLength = [response expectedContentLength];
	
	if([response respondsToSelector:@selector(statusCode)]) {
		self.statusCode = (NSInteger)[(NSHTTPURLResponse *)response statusCode];
	}
}

// implement properly, may be of use
- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
		newCredential = [NSURLCredential credentialWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceNone];
		[[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
	}
	
	// last auth failed, abort!
	else {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		
		[myConnection release];
		[self downloadFailedWithMessage:@"Server needs authentification which is not currently supported"];
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
	NSUInteger bytesReceived = [receivedData length];
	
	// display progress
	if(expectedContentLength != NSURLResponseUnknownLength) {
		CGFloat fraction = bytesReceived / (CGFloat) expectedContentLength;
		[delegate setProgress:fraction];
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(statusCode) {
		if(200 == statusCode) {
			
			// parse the data - we received the eponyms, hooray!
			if(2 == updateAction) {
				[self createEponymsWithData:receivedData];
			}
			
			// the update-check file, let's see if we need to update
			else {
				[delegate setProgress:-1.0];
				[self parseNewEponymCheck:receivedData];
			}
		}
		else {
			NSString *errorMessage;
			if(404 == statusCode) {
				errorMessage = @"The file was not found on the server";
			}
			else {
				errorMessage = [NSString stringWithFormat:@"Server response code: %i", statusCode];
			}
			[self downloadFailedWithMessage:errorMessage];
		}
	}
	// else: Use the Force, Luke!
	else {
		[self downloadFailedWithMessage:@"No statusCode received"];
	}
	
	[myConnection release];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[myConnection release];
	[self downloadFailedWithMessage:[NSString stringWithFormat:@"Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]]];
}
#pragma mark -



#pragma mark Workhorse

// call this to spawn a new thread which imports eponyms from the XML
- (void) createEponymsWithData:(NSData *)XMLData
{
	[XMLData retain];
	[delegate setStatusMessage:@"Creating eponyms..."];
	[delegate setProgress:0.0];
	
	[NSThread detachNewThreadSelector:@selector(parseEponyms:) toTarget:self withObject:XMLData];
	[XMLData release];		// the spawned thread will retain XMLData automatically as long as it needs it
}


// will detach this thread from the main thread because it might run some time - create our own NSAutoreleasePool
- (void) parseEponyms:(NSData *)XMLData
{
	NSAutoreleasePool* myAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	self.numEponymsParsed = 0;
	[categoriesAlreadyInserted removeAllObjects];
	[self emptyDBAndPrepareQueries];
	
	NSString *finalMessage;
	NSError *parseError = nil;
	
	
	// Parse and create			****  (~ 11 sec on iPod touch 1st Gen)
	[self parseXMLData:XMLData parseError:&parseError];			// does the parsing and inserting into memory_database
	// Parsing done				****
	
	
	// Error occurred (we end up here if mustAbortImport was set tu true)
	if(parseError) {
		finalMessage = @"Parser Error";
		[appDelegate eponymImportFailed];
		database = nil;
	}
	
	// cat memory_data to disk
	else {
		[self catMemoryDBToDisk];						// concatenates memory_database to the file database and closes memory_database
		
		if(numEponymsParsed > 0) {
			finalMessage = [NSString stringWithFormat:@"Created %u eponyms", numEponymsParsed];
			
			// update time in GUI and save it in the prefs
			NSDate *nowDate = [NSDate date];
			[delegate updateLabelsWithDateForLastCheck:nil lastUpdate:nowDate usingEponyms:nil];
			
			NSTimeInterval nowInEpoch = [nowDate timeIntervalSince1970];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymUpdate"];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[eponymCreationDate intValue]] forKey:@"usingEponymsOf"];
		}
		else {
			finalMessage = @"No eponyms were created";
		}
	}
	
	// reset GUI
	[delegate setNewEponymsAvailable:NO];
	[delegate setUpdateButtonTitle:@"Check for Eponym Updates"];
	[delegate setUpdateButtonTitleColor:nil];
	[delegate setStatusMessage:finalMessage];
	[delegate setProgress:-1.0];
	
	[delegate setIAmUpdating:NO];
	
	[myAutoreleasePool release];
}


// New eponym check. only runs a few milliseconds (XML has 2 child nodes...), so no extra thread and no NSAutoreleasePool
- (void) parseNewEponymCheck:(NSData *)XMLData
{
	[XMLData retain];
	self.eponymCheckNumEponyms = 0;
	NSString *finalMessage;
	
	
	// Parse			****
	[self parseXMLData:XMLData parseError:nil];
	// Parse finished	****
	
	
	if(!eponymCheckLastUpdateTime) {
		finalMessage = @"No eponymCheckLastUpdateTime!";
	}
	else {
		// compare the dates
		NSNumber *lastEponymUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEponymUpdate"];
		NSNumber *availableEponyms = [NSNumber numberWithInt:eponymCheckLastUpdateTime];
		
		// evaluates to YES when (availableEponyms > lastEponymUpdate) or when no eponyms are present
		BOOL hasNew = (nil == lastEponymUpdate) || [lastEponymUpdate isEqualToNumber:[NSNumber numberWithInt:0]] || (NSOrderedAscending == [lastEponymUpdate compare:availableEponyms]);
		
		
		// *****
		// new eponyms available, show the button to download them
		if(hasNew) {
			finalMessage = @"New eponyms are available!";
			[delegate setUpdateButtonTitle:@"Download New Eponyms"];
			[delegate setUpdateButtonTitleColor:[UIColor redColor]];
			
			[delegate setNewEponymsAvailable:YES];
			[delegate setReadyToLoadNumEponyms:eponymCheckNumEponyms];
		}
		
		
		// *****
		// no new eponyms
		else {
			finalMessage = @"You are up to date";
			[delegate setNewEponymsAvailable:NO];
		}
		
		// save date
		NSDate *nowDate = [NSDate date];
		[delegate updateLabelsWithDateForLastCheck:nowDate lastUpdate:nil usingEponyms:nil];
		
		NSTimeInterval nowInEpoch = [nowDate timeIntervalSince1970];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastEponymCheck"];
	}
	
	[XMLData release];
	
	[delegate setStatusMessage:finalMessage];
	[delegate setIAmUpdating:NO];
}
#pragma mark -



#pragma mark Parser Delegate
- (void) parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void) parseXMLData:(NSData *)data parseError:(NSError **) error
{	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	
	// Parser config
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	// Parse
	[parser parse];
	
	NSError *parseError = [parser parserError];
	if(parseError && error) {
		*error = parseError;
	}
	
	[parser release];
}


// START ***
- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if(qName) {
		elementName = qName;
	}
	
	// parsing the EPONYMS
	if(2 == updateAction) {
		
		// Start an eponym  <eponym id="id_string">
		if([elementName isEqualToString:@"eponym"]) {
			self.currentlyParsedEponym = [NSMutableDictionary dictionary];
			self.categoriesOfCurrentEponym = [NSMutableArray array];
		}
		
		// Start one of the properties  <name>  <desc>  <cat>  <c>  <e>
		else if([elementName isEqualToString:@"name"] || [elementName isEqualToString:@"desc"] || [elementName isEqualToString:@"cat"] || [elementName isEqualToString:@"c"] || [elementName isEqualToString:@"e"]) {
			self.contentOfCurrentXMLNode = [NSMutableString string];
		}
		
		// Start the XML root element  <root created="epoch-integer">
		else if([elementName isEqualToString:@"root"]) {
			self.eponymCreationDate = [attributeDict valueForKey:@"created"];
		}
		
		// no node we care about. set contentOfCurrentXMLNode to nil so we ignore data of this node
		else {
			self.contentOfCurrentXMLNode = nil;
		}
	}
	
	// parsing the eponym CHECK file
	else {
		if([elementName isEqualToString:@"lastupdate"]) {
			self.eponymCheckLastUpdateTime = [[attributeDict valueForKey:@"epoch"] intValue];
		}
		else if([elementName isEqualToString:@"size"]) {
			self.eponymCheckFileSize = [[attributeDict valueForKey:@"byte"] intValue];
			self.eponymCheckNumEponyms = [[attributeDict valueForKey:@"num"] intValue];
		}
	}
}


// END *** the parser ended an element - save contentOfCurrentXMLNode accordingly
- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
	if(qName) {
		elementName = qName;
	}
	
	// parsing the EPONYMS
	if(2 == updateAction) {
		
		// Ended an eponym - insert the eponym and the categories into the database
		if([elementName isEqualToString:@"eponym"]) {
			if(self.mustAbortImport) {
				[parser abortParsing];
			}
			
			self.numEponymsParsed += 1;
			
			// insert into database *****
			[self insertEponymIntoDatabase:currentlyParsedEponym withCategories:categoriesOfCurrentEponym];
			
			// show progress
			if(0 == numEponymsParsed % 100) {
				CGFloat fraction = numEponymsParsed / (CGFloat) readyToLoadNumEponyms;
				[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:fraction] waitUntilDone:NO];
			}
		}
		
		// Ended eponym attributes  <name> <desc> <c> <e>
		else if([elementName isEqualToString:@"name"] || [elementName isEqualToString:@"desc"] || [elementName isEqualToString:@"c"] || [elementName isEqualToString:@"e"]) {
			[currentlyParsedEponym setObject:[contentOfCurrentXMLNode copy] forKey:elementName];
		}
		
		// Ended a category  <cat>
		else if([elementName isEqualToString:@"cat"]) {
			[categoriesOfCurrentEponym addObject:[contentOfCurrentXMLNode copy]];
		}
	}
}

// called when the parser has a string - add it to our contentOfCurrentXMLNode string
- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if(contentOfCurrentXMLNode) {
		[contentOfCurrentXMLNode appendString:string];
	}
}

// gets called on error AND on abort
- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
}
#pragma mark -



#pragma mark SQLite

// Inserts the eponym and its categories into the database (if not already present) and links them
- (void) insertEponymIntoDatabase:(NSDictionary *)eponymDict withCategories:(NSArray *)categoryArray
{
	if(!memory_database) {
		NSAssert(0, @"memory_database is not present!");
	}
	
	[eponymDict retain];
	[categoryArray retain];
	
	NSInteger insert_eponym_id = 0;
	NSInteger insert_category_id = 0;
	
	
	// Insert the eponym **
	sqlite3_bind_text(insert_eponym_query, 1, [[eponymDict objectForKey:@"name"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_eponym_query, 2, [[eponymDict objectForKey:@"desc"] UTF8String], -1, SQLITE_TRANSIENT);
	if([eponymDict objectForKey:@"c"]) {
		sqlite3_bind_int(insert_eponym_query, 3, [self epochForStringDate:[eponymDict objectForKey:@"c"]]);
	}
	if([eponymDict objectForKey:@"e"]) {
		sqlite3_bind_int(insert_eponym_query, 4, [self epochForStringDate:[eponymDict objectForKey:@"e"]]);
	}
	
	NSInteger success = sqlite3_step(insert_eponym_query);
	if(success == SQLITE_DONE) {
		insert_eponym_id = sqlite3_last_insert_rowid(memory_database);
	}
	else {
		NSAssert1(0, @"Error: Failed to insert eponym: '%s'.", sqlite3_errmsg(memory_database));
	}
	sqlite3_reset(insert_eponym_query);
	
	
	// Categories and category-eponym-linker **
	for(NSString *category in categoryArray) {
		if([category isEqualToString:@""]) {
			continue;
		}
		insert_category_id = 0;
		
		// was the category already inserted? Get its ID
		NSArray *allExistingCategories = [categoriesAlreadyInserted allKeys];
		for(NSString *cat in allExistingCategories) {
			if([category isEqualToString:cat]) {
				insert_category_id = [[categoriesAlreadyInserted objectForKey:cat] intValue];
				break;
			}
		}
		
		// new category - insert and remember for later
		if(0 == insert_category_id) {
			sqlite3_bind_text(insert_category_query, 1, [category UTF8String], -1, SQLITE_TRANSIENT);
			int success = sqlite3_step(insert_category_query);
			if(SQLITE_DONE == success) {
				insert_category_id = sqlite3_last_insert_rowid(memory_database);
				[categoriesAlreadyInserted setObject:[NSNumber numberWithInt:insert_category_id] forKey:category];
			}
			else {
				NSAssert1(0, @"Error: Failed to insert category: '%s'.", sqlite3_errmsg(memory_database));
			}
			sqlite3_reset(insert_category_query);
		}
		
		// link eponyms to category
		sqlite3_bind_int(insert_linker_query, 1, insert_category_id);
		sqlite3_bind_int(insert_linker_query, 2, insert_eponym_id);
		int success = sqlite3_step(insert_linker_query);
		if(SQLITE_DONE != success) {
			NSAssert1(0, @"Error: Failed to link eponym to category: '%s'.", sqlite3_errmsg(memory_database));
		}
		sqlite3_reset(insert_linker_query);
	}
	
	[eponymDict release];
	[categoryArray release];
}

- (void) createInMemoryDatabase
{
	// Create the in-memory database for faster insert operation
	if(SQLITE_OK == sqlite3_open(":memory:", &memory_database)) {		// sqlite3_open_v2(":memory:", &memory_database, SQLITE_OPEN_CREATE, NULL)
		char *err;
		NSDictionary *creationQueries = [appDelegate databaseCreationQueries];
		NSString *createCatTable = [creationQueries objectForKey:@"createCatTable"];
		NSString *createLinkTable = [creationQueries objectForKey:@"createLinkTable"];
		NSString *createEpoTable = [creationQueries objectForKey:@"createEpoTable"];
		
		sqlite3_exec(memory_database, [createCatTable UTF8String], NULL, NULL, &err);
		if(err) {
			NSAssert1(0, @"Error: Failed to execute createCatTable: '%s'.", sqlite3_errmsg(memory_database));
		}
		
		sqlite3_exec(memory_database, [createLinkTable UTF8String], NULL, NULL, &err);
		if(err) {
			NSAssert1(0, @"Error: Failed to execute createLinkTable: '%s'.", sqlite3_errmsg(memory_database));
		}
		
		sqlite3_exec(memory_database, [createEpoTable UTF8String], NULL, NULL, &err);
		if(err) {
			NSAssert1(0, @"Error: Failed to execute createEpoTable: '%s'.", sqlite3_errmsg(memory_database));
		}
		
	}
	else {
		sqlite3_close(memory_database);
		NSAssert1(0, @"Failed to open new memory_database: '%s'.", sqlite3_errmsg(memory_database));
	}
}


- (void) emptyDBAndPrepareQueries
{
	database = [appDelegate database];
	if(nil == database) {
		[appDelegate connectToDBAndCreateIfNeeded];
		database = [appDelegate database];
	}
	
	[self createInMemoryDatabase];
	
	char *err;
	
	// empty file database
	sqlite3_exec(database, "DELETE FROM categories", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: Failed to empty categories table: '%s'.", sqlite3_errmsg(database));
	}
	
	sqlite3_exec(database, "DELETE FROM category_eponym_linker", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: Failed to empty category_eponym_linker table: '%s'.", sqlite3_errmsg(database));
	}
	
	sqlite3_exec(database, "DELETE FROM eponyms", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: Failed to empty eponyms table: '%s'.", sqlite3_errmsg(database));
	}
	
	// prepare statements
	const char *qry1 = "INSERT INTO eponyms (eponym_en, text, created, lastedit) VALUES (?, ?, ? ,?)";
	if(sqlite3_prepare_v2(memory_database, qry1, -1, &insert_eponym_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_eponym_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry2 = "INSERT INTO categories (category_en) VALUES (?)";
	if(sqlite3_prepare_v2(memory_database, qry2, -1, &insert_category_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_category_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry3 = "INSERT INTO category_eponym_linker (category_id, eponym_id) VALUES (?, ?)";
	if(sqlite3_prepare_v2(memory_database, qry3, -1, &insert_linker_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_linker_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	
	// we need to reload the eponyms after this
	[delegate setNeedToReloadEponyms:YES];
}


- (void) catMemoryDBToDisk
{
	NSString *sqlPath = [appDelegate databaseFilePath];
	char *err;
	
	// ATTACH main database to :memory: database
	NSString *attach_qry = [NSString stringWithFormat:@"ATTACH DATABASE \"%@\" AS real_db", sqlPath];
	sqlite3_exec(memory_database, [attach_qry UTF8String], NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to ATTACH DATABASE: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// INSERT eponyms
	sqlite3_exec(memory_database, "INSERT INTO real_db.eponyms SELECT * FROM main.eponyms", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat eponyms to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// INSERT categories
	sqlite3_exec(memory_database, "INSERT INTO real_db.categories SELECT * FROM main.categories", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat categories to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// INSERT links
	sqlite3_exec(memory_database, "INSERT INTO real_db.category_eponym_linker SELECT * FROM main.category_eponym_linker", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat category-eponym-links to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
}


- (void) finalizeQueries
{
	if(insert_eponym_query) {
		sqlite3_finalize(insert_eponym_query);
		insert_eponym_query = nil;
	}
	if(insert_category_query) {
		sqlite3_finalize(insert_category_query);
		insert_category_query = nil;
	}
	if(insert_linker_query) {
		sqlite3_finalize(insert_linker_query);
		insert_linker_query = nil;
	}
	
	sqlite3_close(memory_database);
	memory_database = nil;
}
#pragma mark -



#pragma mark GUI

// handles GUI stuff when the download fails
- (void) downloadFailedWithMessage:(NSString *)message
{
	[delegate setStatusMessage:nil];
	[delegate setProgress:-1.0];
	[delegate setIAmUpdating:NO];
	
	[delegate alertViewWithTitle:@"Download Failed" message:message cancelTitle:@"OK"];
}

- (void) updateProgress:(NSNumber *)progress
{
	[delegate progressView].progress = [progress floatValue];
}
#pragma mark -



#pragma mark Utilities

// converts US-style dates to epoch time (feed: @"3/28/1981")
- (NSInteger) epochForStringDate:(NSString *)stringDate
{
	NSInteger epoch = 0;
	[stringDate retain];
	
	// split the date
	NSArray *dateParts = [stringDate componentsSeparatedByString:@"/"];
	if([dateParts count] >= 3) {
		NSUInteger day = [[dateParts objectAtIndex:0] intValue];
		NSUInteger month = [[dateParts objectAtIndex:1] intValue];
		NSUInteger year = [[dateParts objectAtIndex:2] intValue];
		
		year = (year < 100) ? (year += 1900) : year;
		
		// compose the date
		NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
		[components setYear:year];
		[components setMonth:month];
		[components setDay:day];
		
		// get the date
		NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDate *date = [gregorianCalendar dateFromComponents:components];
		
		[stringDate release];
		epoch = [date timeIntervalSince1970];
	}
	
	return epoch;
}



@end
