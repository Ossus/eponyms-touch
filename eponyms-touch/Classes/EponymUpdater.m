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

#define URL_LOAD_TIMEOUT 20.0



@interface EponymUpdater (Private)

// Main functions
- (void) parseEponyms:(NSData *)XMLData;
- (void) parseNewEponymCheck:(NSData *)XMLData;
- (void) parseXMLData:(NSData *)data parseError:(NSError **) error;

// SQLite
- (void) insertCategory:(NSDictionary *)category;
- (NSUInteger) insertEponymIntoDatabase:(NSDictionary *)eponymDict;
- (void) linkEponym:(NSUInteger)eponym_id toCategories:(NSArray *)categoryArray;

- (void) prepareDBAndQueries;
- (void) catMemoryDBToDisk;
- (void) finalizeQueries;

// Utilities
- (void) downloadFailedWithMessage:(NSString *)message;
- (NSInteger) epochForStringDate:(NSString *)stringDate;

@end

#pragma mark -



#pragma mark SQLite statics

static sqlite3_stmt *insert_category_query = nil;
static sqlite3_stmt *insert_eponym_query = nil;
static sqlite3_stmt *insert_linker_query = nil;
static sqlite3_stmt *get_starred_query = nil;
static sqlite3_stmt *star_eponym_query = nil;

#pragma mark -


@implementation EponymUpdater

@synthesize delegate, viewController, updateAction, newEponymsAvailable, statusMessage;
@synthesize isDownloading, downloadFailed, eponymUpdateCheckURL, eponymXMLURL, statusCode, expectedContentLength, myConnection, receivedData;
@synthesize isParsing, mustAbortImport, parseFailed, eponymCheck_eponymUpdateTime, eponymCheckFileSize, readyToLoadNumEponyms, eponymCreationDate, currentlyParsedNode, contentOfCurrentXMLNode, categoriesOfCurrentEponym, categoriesAlreadyInserted, numEponymsParsed;


- (id) initWithDelegate:(id)myDelegate
{
	self = [super init];
	if(self) {
		self.delegate = myDelegate;
		self.updateAction = 1;							// 1 = load new check, 2 = download and install XML, 3 = load and install local XML
		self.receivedData = [NSMutableData data];
		mustAbortImport = NO;
		
		// NSBundle Info.plist
		NSDictionary *infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.eponymUpdateCheckURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"eponymUpdateCheckURL"]];
		self.eponymXMLURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"eponymXMLURL"]];
	}
	
	return self;
}


- (void) dealloc
{
	self.delegate = nil;
	self.myConnection = nil;
	self.receivedData = nil;
	
	self.statusMessage = nil;
	self.eponymUpdateCheckURL = nil;
	self.eponymXMLURL = nil;
	
	self.eponymCreationDate = nil;
	self.currentlyParsedNode = nil;
	self.contentOfCurrentXMLNode = nil;
	self.categoriesOfCurrentEponym = nil;
	self.categoriesAlreadyInserted = nil;
	
	// SQLite
	[self finalizeQueries];
	
	[super dealloc];
}
#pragma mark -



#pragma mark Workhorse
- (void) startUpdaterAction
{
	self.mustAbortImport = NO;
	
	// action 1 and 2 start with a download
	if(updateAction <= 2) {
		self.isDownloading = YES;
		self.statusMessage = @"Downloading...";
		
		[delegate updaterDidStartAction:self];
		if(viewController) {
			[viewController updaterDidStartAction:self];
			if([viewController respondsToSelector:@selector(updater:progress:)]) {
				[viewController updater:self progress:0.0];
			}
		}
		
		// check desired action: 1 = check for updates, 2 = download and install eponyms, 3 = install local eponyms
		NSURL *url;
		if(2 == updateAction) {
			url = self.eponymXMLURL;
		}
		else {
			url = self.eponymUpdateCheckURL;
		}
		
		// create the request and start downloading by making the connection
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:URL_LOAD_TIMEOUT];
		self.myConnection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
		
		if(!myConnection) {
			[self downloadFailedWithMessage:@"Could not create the NSURLConnection object"];
		}
	}
	
	// action 3 loads XML from disk
	else {
		readyToLoadNumEponyms = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"numberOfIncludedEponyms"] intValue];
		
		NSString *eponymXMLPath = [NSBundle pathForResource:@"eponyms" ofType:@"xml" inDirectory:[[NSBundle mainBundle] bundlePath]];
		NSData *includedXMLData = [NSData dataWithContentsOfFile:eponymXMLPath];
		[self createEponymsWithData:includedXMLData];
	}
}


// New eponym check. only runs a few milliseconds (XML has 2 child nodes...), so no extra thread and therefore no NSAutoreleasePool
- (void) parseNewEponymCheck:(NSData *)XMLData
{
	self.isParsing = YES;
	self.statusMessage = nil;
	
	[delegate updaterDidStartAction:self];
	if(viewController) {
		[viewController updaterDidStartAction:self];
	}
	
	
	// Parse			****
	[XMLData retain];
	[self parseXMLData:XMLData parseError:nil];
	[XMLData release];
	// Parse finished	****
	
	
	if(!eponymCheck_eponymUpdateTime) {
		self.parseFailed = YES;
		self.statusMessage = @"No eponymCheck_eponymUpdateTime!";
		self.newEponymsAvailable = NO;
	}
	
	// success, evaluate newEponymsAvailable to YES when (availableEponyms > usingEponymsOf) or when no eponyms are currently present
	else {
		self.parseFailed = NO;
		NSInteger usingEponymsOf = [(eponyms_touchAppDelegate *)delegate usingEponymsOf];
		self.newEponymsAvailable = (0 == usingEponymsOf) || (eponymCheck_eponymUpdateTime > usingEponymsOf);
	}
	
	// inform the delegates
	self.isParsing = NO;
	if(viewController) {
		[viewController updater:self didEndActionSuccessful:!self.parseFailed];
	}
	[delegate updater:self didEndActionSuccessful:!self.parseFailed];
	self.updateAction = newEponymsAvailable ? 2 : 1;
}


// call this to spawn a new thread which imports eponyms from the XML
- (void) createEponymsWithData:(NSData *)XMLData
{
	self.isParsing = YES;
	self.statusMessage = @"Creating eponyms...";
	
	[delegate updaterDidStartAction:self];
	if(viewController) {
		[viewController updaterDidStartAction:self];
		if([viewController respondsToSelector:@selector(updater:progress:)]) {
			[viewController updater:self progress:0.0];
		}
	}
	
	// the spawned thread will retain XMLData automatically as long as it needs it. No need to retain it here
	[NSThread detachNewThreadSelector:@selector(parseEponyms:) toTarget:self withObject:XMLData];
}


// will detach this thread from the main thread - create our own NSAutoreleasePool
- (void) parseEponyms:(NSData *)XMLData
{
	NSAutoreleasePool *myAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	self.numEponymsParsed = 0;
	self.categoriesAlreadyInserted = [NSMutableDictionary dictionary];
	[self prepareDBAndQueries];
	
	NSError *parseError = nil;
	
	
	// Parse and create			****
	NSLog(@"begin...");
	//* --
	sqlite3_stmt *begin_transaction_stmt;
	const char *beginTrans = "BEGIN EXCLUSIVE TRANSACTION";
	if(sqlite3_prepare_v2(memory_database, beginTrans, -1, &begin_transaction_stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: Failed to prepare exclusive transaction: '%s'.", sqlite3_errmsg(memory_database));
	}
	if(SQLITE_DONE != sqlite3_step(begin_transaction_stmt)) {
		NSAssert1(0, @"Error: Failed to step on begin_transaction_stmt: '%s'.", sqlite3_errmsg(memory_database));
	}
	sqlite3_finalize(begin_transaction_stmt);
	// --	*/
	[self parseXMLData:XMLData parseError:&parseError];			// does the parsing and inserting into memory_database
	//* --
	sqlite3_stmt *end_transaction_stmt;
	const char *endTrans = "COMMIT";
	if(sqlite3_prepare_v2(memory_database, endTrans, -1, &end_transaction_stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to commit transaction: '%s'.", sqlite3_errmsg(memory_database));
	}
	if(SQLITE_DONE != sqlite3_step(end_transaction_stmt)) {
		NSAssert1(0, @"Error: Failed to step on end_transaction_stmt: '%s'.", sqlite3_errmsg(memory_database));
	}
	sqlite3_finalize(end_transaction_stmt);
	// --	*/
	NSLog(@"...done");
	// Parsing done				****
	
	
	// Error occurred (we also end up here if mustAbortImport was set to true)
	if(parseError) {
		self.parseFailed = YES;
		self.statusMessage = mustAbortImport ? @"Import Aborted" : @"Parser Error";
		numEponymsParsed = 0;
		database = nil;
	}
	
	// cat memory_data to disk (also re-sets starred eponyms)
	else {
		self.parseFailed = NO;
		[self catMemoryDBToDisk];			// concatenates memory_database to the file database and closes memory_database
	}
	
	// Clean up
	self.isParsing = NO;
	self.categoriesAlreadyInserted = nil;
	self.newEponymsAvailable = NO;
	
	// inform the delegates
	if(viewController) {
		[viewController updater:self didEndActionSuccessful:!self.parseFailed];
	}
	[delegate updater:self didEndActionSuccessful:!self.parseFailed];
	self.updateAction = parseFailed ? updateAction : 1;
	
	[myAutoreleasePool release];
}
#pragma mark -



#pragma mark Download delegate

// called right before we send a request
- (NSURLRequest *) connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	NSURLRequest *newRequest = request;
	
	// Should implement this in case we receive a redirect
	if(redirectResponse) {
		newRequest = nil;
		
		self.myConnection = nil;
		[self downloadFailedWithMessage:@"Server sent a redirect response. Maybe you must first login to the network you are connected."];
	}
	return newRequest;
}

// called whenever we receive a response from the server following our request
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[receivedData setLength:0];
	self.expectedContentLength = [response expectedContentLength];
	
	if([response respondsToSelector:@selector(statusCode)]) {
		self.statusCode = (NSInteger)[(NSHTTPURLResponse *)response statusCode];
	}
}

// implementation won't be necessary since our resources won't be password protected
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
		
		self.myConnection = nil;
		[self downloadFailedWithMessage:@"Server needs authentification which is not currently supported"];
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(mustAbortImport) {
		[connection cancel];
		[self downloadFailedWithMessage:@"Download Aborted"];
		return;
	}
	
	[receivedData appendData:data];
	NSUInteger bytesReceived = [receivedData length];
	
	// display progress
	if(viewController && [viewController respondsToSelector:@selector(updater:progress:)] && (expectedContentLength != NSURLResponseUnknownLength)) {
		CGFloat fraction = bytesReceived / (CGFloat) expectedContentLength;
		[viewController updater:self progress:fraction];
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	self.isDownloading = NO;
	self.myConnection = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(statusCode) {
		if(200 == statusCode) {
			self.downloadFailed = NO;
			
			// the update-check file, let's see if we need to update
			if(1 == updateAction) {
				if([delegate respondsToSelector:@selector(updater:progress:)]) {
					[delegate updater:self progress:-1.0];
				}
				if(viewController && [viewController respondsToSelector:@selector(updater:progress:)]) {
					[viewController updater:self progress:-1.0];
				}
				[self parseNewEponymCheck:receivedData];
			}
			
			// parse the data - we received the eponyms, hooray!
			else {
				[self createEponymsWithData:receivedData];
			}
		}
		
		// FAIL
		else {
			NSString *errorMessage;
			if(404 == statusCode) {
				errorMessage = @"The file was not found on the server";
			}
			else {
				errorMessage = [NSString stringWithFormat:@"Failed with server response code %i", statusCode];
			}
			[self downloadFailedWithMessage:errorMessage];
		}
	}
	// else: Use the Force, Luke! (not)
	else {
		[self downloadFailedWithMessage:@"No statusCode received"];
	}
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	self.myConnection = nil;
	[self downloadFailedWithMessage:[NSString stringWithFormat:@"Error - %@ %@",
									 [error localizedDescription],
									 [[error userInfo] objectForKey:NSErrorFailingURLStringKey]]];
}
#pragma mark -



#pragma mark Parser Delegate
- (void) parseXMLData:(NSData *)data parseError:(NSError **) error
{	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	
	// Parser config
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	// Parse
	innerPool = [[NSAutoreleasePool alloc] init];
	[parser parse];
	[innerPool release];
	
	NSError *parseError = [parser parserError];
	if(parseError && error) {
		*error = parseError;
	}
	
	[parser release];
}


- (void) parserDidStartDocument:(NSXMLParser *)parser
{
}


// START ELEMENT ***
- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if(qName) {
		elementName = qName;
	}
	
	// ****
	// parsing eponyms.xml
	if(updateAction >= 2) {
		
		// Start an eponym  <eponym id="id_string">
		if([elementName isEqualToString:@"eponym"]) {
			self.currentlyParsedNode = [NSMutableDictionary dictionaryWithObject:[attributeDict valueForKey:@"id"] forKey:@"identifier"];
			self.categoriesOfCurrentEponym = [NSMutableArray array];
		}
		
		// Start one of the properties  <name>  <desc>  <cat>  <c>  <e>
		else if([elementName isEqualToString:@"name"] || [elementName isEqualToString:@"desc"] || [elementName isEqualToString:@"cat"] || [elementName isEqualToString:@"c"] || [elementName isEqualToString:@"e"]) {
			self.contentOfCurrentXMLNode = [NSMutableString string];
		}
		
		// Start a category  <category tag="TAG" title="Category name" />
		else if([elementName isEqualToString:@"category"]) {
			[self insertCategory:attributeDict];
		}
		
		// Start the XML root element  <root created="epoch-integer">
		else if([elementName isEqualToString:@"root"]) {
			self.eponymCreationDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[[attributeDict valueForKey:@"created"] intValue]];
		}
		
		// no node we care about. set contentOfCurrentXMLNode to nil so we ignore data of this node
		else {
			self.contentOfCurrentXMLNode = nil;
		}
	}
	
	// ****
	// parsing the eponym CHECK file
	else {
		if([elementName isEqualToString:@"lastupdate"]) {
			self.eponymCheck_eponymUpdateTime = [[attributeDict valueForKey:@"epoch"] intValue];
		}
		else if([elementName isEqualToString:@"size"]) {
			self.eponymCheckFileSize = [[attributeDict valueForKey:@"byte"] intValue];
			self.readyToLoadNumEponyms = [[attributeDict valueForKey:@"num"] intValue];
		}
	}
}


// END ELEMENT *** the parser ended an element - save contentOfCurrentXMLNode accordingly
- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
	if(qName) {
		elementName = qName;
	}
	
	// ****
	// parsing the EPONYMS
	if(updateAction >= 2) {
		
		// Ended an eponym - insert the eponym and the categories into the database
		if([elementName isEqualToString:@"eponym"]) {
			if(mustAbortImport) {
				[parser abortParsing];
			}
			
			self.numEponymsParsed += 1;
			
			// **
			// Insert eponym, link to categories and clean up
			NSUInteger ep_id = [self insertEponymIntoDatabase:currentlyParsedNode];
			[self linkEponym:ep_id toCategories:categoriesOfCurrentEponym];
			self.currentlyParsedNode = nil;
			self.categoriesOfCurrentEponym = nil;
			
			// show progress and flush the innerPool
			if(0 == numEponymsParsed % 50) {
				CGFloat fraction = numEponymsParsed / (CGFloat) readyToLoadNumEponyms;
				[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:fraction] waitUntilDone:NO];
				
				[innerPool release];
				innerPool = [[NSAutoreleasePool alloc] init];
			}
		}
		
		// Ended eponym attributes  <name> <desc> <c> <e>
		else if([elementName isEqualToString:@"name"] || [elementName isEqualToString:@"desc"] || [elementName isEqualToString:@"c"] || [elementName isEqualToString:@"e"]) {
			[currentlyParsedNode setObject:[[contentOfCurrentXMLNode copy] autorelease] forKey:elementName];
			self.contentOfCurrentXMLNode = nil;
		}
		
		// Ended a category  <cat>
		else if([elementName isEqualToString:@"cat"]) {
			[categoriesOfCurrentEponym addObject:[[contentOfCurrentXMLNode copy] autorelease]];
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

// gets called on error and on abort instead of parserDidEndDocument
- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
}

// will NOT be called when we abort!
- (void) parserDidEndDocument:(NSXMLParser *)parser
{
}
#pragma mark -



#pragma mark SQLite
- (void) insertCategory:(NSDictionary *)category
{
	if(category) {
		[category retain];
		NSString *tag = [category objectForKey:@"tag"];
		sqlite3_bind_text(insert_category_query, 1, [tag UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(insert_category_query, 2, [[category objectForKey:@"title"] UTF8String], -1, SQLITE_TRANSIENT);
		
		if(SQLITE_DONE == sqlite3_step(insert_category_query)) {
			[categoriesAlreadyInserted setObject:[NSNumber numberWithInt:sqlite3_last_insert_rowid(memory_database)] forKey:tag];
		}
		else {
			NSAssert2(0, @"Error: Failed to insert category %@: '%s'.", tag, sqlite3_errmsg(memory_database));
		}
		sqlite3_reset(insert_category_query);
		[category release];
	}
}

- (NSUInteger) insertEponymIntoDatabase:(NSDictionary *)eponymDict
{
	if(!memory_database) {
		NSAssert(0, @"memory_database is not present!");
	}
	
	[eponymDict retain];
	NSInteger insert_eponym_id = 0;
	
	// Insert the eponym **
	sqlite3_bind_text(insert_eponym_query, 1, [[eponymDict objectForKey:@"identifier"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_eponym_query, 2, [[eponymDict objectForKey:@"name"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_eponym_query, 3, [[eponymDict objectForKey:@"desc"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(insert_eponym_query, 4, [eponymDict objectForKey:@"c"] ? [self epochForStringDate:[eponymDict objectForKey:@"c"]] : 0);
	sqlite3_bind_int(insert_eponym_query, 5, [eponymDict objectForKey:@"e"] ? [self epochForStringDate:[eponymDict objectForKey:@"e"]] : 0);
	
	if(SQLITE_DONE == sqlite3_step(insert_eponym_query)) {
		insert_eponym_id = sqlite3_last_insert_rowid(memory_database);
	}
	else {
		NSAssert2(0, @"Error: Failed to insert eponym %@: '%s'.", [eponymDict objectForKey:@"identifier"], sqlite3_errmsg(memory_database));
	}
	sqlite3_reset(insert_eponym_query);
	[eponymDict release];
	
	return insert_eponym_id;
}

- (void) linkEponym:(NSUInteger)eponym_id toCategories:(NSArray *)categoryArray
{
	if([categoryArray count] > 0) {
		[categoryArray retain];
		
		for(NSString *category in categoryArray) {
			if([category isEqualToString:@""]) {
				continue;
			}
			
			// link eponyms to category
			NSNumber *existingCatID = [categoriesAlreadyInserted objectForKey:category];
			NSUInteger insert_category_id = (nil == existingCatID) ? 0 : [existingCatID intValue];
			
			if(insert_category_id > 0) {
				sqlite3_bind_int(insert_linker_query, 1, insert_category_id);
				sqlite3_bind_int(insert_linker_query, 2, eponym_id);
				
				if(SQLITE_DONE != sqlite3_step(insert_linker_query)) {
					NSAssert1(0, @"Error: Failed to link eponym to category: '%s'.", sqlite3_errmsg(memory_database));
				}
				sqlite3_reset(insert_linker_query);
			}
			// else should not happen
		}
		
		[categoryArray release];
	}
}



// Call before we start to parse
- (void) prepareDBAndQueries
{
	database = [(eponyms_touchAppDelegate *)delegate database];
	if(nil == database) {
		[(eponyms_touchAppDelegate *)delegate connectToDBAndCreateIfNeeded];
		database = [(eponyms_touchAppDelegate *)delegate database];
	}
	
	char *err;
	
	// ****
	// Create the in-memory database (for faster insert operation)
	if(SQLITE_OK == sqlite3_open(":memory:", &memory_database)) {		// sqlite3_open_v2(":memory:", &memory_database, SQLITE_OPEN_CREATE, NULL)
		NSDictionary *creationQueries = [(eponyms_touchAppDelegate *)delegate databaseCreationQueries];
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
	
	
	// ****
	// prepare statements
	const char *qry0 = "INSERT INTO categories (tag, category_en) VALUES (?, ?)";
	if(sqlite3_prepare_v2(memory_database, qry0, -1, &insert_category_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_category_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry1 = "INSERT INTO eponyms (identifier, eponym_en, text_en, created, lastedit) VALUES (?, ?, ?, ?, ?)";
	if(sqlite3_prepare_v2(memory_database, qry1, -1, &insert_eponym_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_eponym_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry3 = "INSERT INTO category_eponym_linker (category_id, eponym_id) VALUES (?, ?)";
	if(sqlite3_prepare_v2(memory_database, qry3, -1, &insert_linker_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_linker_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry4 = "UPDATE eponyms SET starred = 1 WHERE identifier = ?";
	if(sqlite3_prepare_v2(database, qry4, -1, &star_eponym_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare star_eponym_query: '%s'.", sqlite3_errmsg(database));
	}
}


// empties the old database after saving the starred identifiers and fills it from the memory database
- (void) catMemoryDBToDisk
{
	self.statusMessage = @"Finishing...";
	[delegate updaterDidStartAction:self];
	if(viewController) {
		[viewController updaterDidStartAction:self];
	}
	
	
	// ****
	// Save starred eponyms (we will soon purge all eponyms, insert the new ones and then re-star them)
	char *err;
	NSMutableArray *starredIdentifiers = [NSMutableArray array];
	if(!get_starred_query) {
		const char *qry = "SELECT identifier FROM eponyms WHERE starred = 1";
		if(sqlite3_prepare_v2(database, qry, -1, &get_starred_query, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare get_starred_query: '%s'.", sqlite3_errmsg(database));
		}
	}
	while(sqlite3_step(get_starred_query) == SQLITE_ROW) {
		char *identifier = (char *)sqlite3_column_text(get_starred_query, 0);
		[starredIdentifiers addObject:[NSString stringWithUTF8String:identifier]];
	}
	sqlite3_reset(get_starred_query);
	
	
	// ****
	// empty current database
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
	
	
	// ****
	// ATTACH main database to :memory: database
	NSString *sqlPath = [(eponyms_touchAppDelegate *)delegate databaseFilePath];
	NSString *attach_qry = [NSString stringWithFormat:@"ATTACH DATABASE \"%@\" AS real_db", sqlPath];
	sqlite3_exec(memory_database, [attach_qry UTF8String], NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to ATTACH DATABASE: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// INSERT eponyms and categories and link them
	sqlite3_exec(memory_database, "INSERT INTO real_db.eponyms SELECT * FROM main.eponyms", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat eponyms to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	sqlite3_exec(memory_database, "INSERT INTO real_db.categories SELECT * FROM main.categories", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat categories to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	sqlite3_exec(memory_database, "INSERT INTO real_db.category_eponym_linker SELECT * FROM main.category_eponym_linker", NULL, NULL, &err);
	if(err) {
		NSAssert1(0, @"Error: failed to cat category-eponym-links to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// re-star eponyms (could do this in insertEponymIntoDatabase:, but should be faster this way)
	if([starredIdentifiers count] > 0) {
		for(NSString *identifier in starredIdentifiers) {
			sqlite3_bind_text(star_eponym_query, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
			
			if(SQLITE_DONE != sqlite3_step(star_eponym_query)) {
				NSAssert1(0, @"Error: Failed to star eponym: '%s'.", sqlite3_errmsg(memory_database));
			}
			sqlite3_reset(star_eponym_query);
		}
	}
	
	[self finalizeQueries];
}


- (void) finalizeQueries
{
	if(insert_category_query) {
		sqlite3_finalize(insert_category_query);
		insert_category_query = nil;
	}
	if(insert_eponym_query) {
		sqlite3_finalize(insert_eponym_query);
		insert_eponym_query = nil;
	}
	if(insert_linker_query) {
		sqlite3_finalize(insert_linker_query);
		insert_linker_query = nil;
	}
	if(get_starred_query) {
		sqlite3_finalize(get_starred_query);
		get_starred_query = nil;
	}
	if(star_eponym_query) {
		sqlite3_finalize(star_eponym_query);
		star_eponym_query = nil;
	}
	
	if(memory_database) {
		sqlite3_close(memory_database);
		memory_database = nil;
	}
}
#pragma mark -



#pragma mark Utilities
- (void) downloadFailedWithMessage:(NSString *)message
{
	self.isDownloading = NO;
	self.downloadFailed = YES;
	self.statusMessage = message;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(viewController) {
		[viewController updater:self didEndActionSuccessful:NO];
	}
	[delegate updater:self didEndActionSuccessful:NO];
}

- (void) updateProgress:(NSNumber *)progress
{
	if([delegate respondsToSelector:@selector(updater:progress:)]) {
		[delegate updater:self progress:[progress floatValue]];
	}
	if(viewController && [viewController respondsToSelector:@selector(updater:progress:)]) {
		[viewController updater:self progress:[progress floatValue]];
	}
}


// converts US-style dates to epoch time (feed: @"3/28/1981")
- (NSInteger) epochForStringDate:(NSString *)stringDate
{
	NSInteger epoch = 0;
	[stringDate retain];
	
	// split the date
	NSArray *dateParts = [stringDate componentsSeparatedByString:@"/"];
	if([dateParts count] >= 3) {
		NSUInteger month = [[dateParts objectAtIndex:0] intValue];
		NSUInteger day = [[dateParts objectAtIndex:1] intValue];
		NSUInteger year = [[dateParts objectAtIndex:2] intValue];
		
		year = (year < 100) ? ((year < 90) ? (year += 2000) : (year += 1900)) : year;
		
		// compose the date
		NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
		[components setYear:year];
		[components setMonth:month];
		[components setDay:day];
		
		// get the date
		NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDate *date = [gregorianCalendar dateFromComponents:components];
		
		epoch = [date timeIntervalSince1970];
	}
	
	[stringDate release];
	
	return epoch;
}



@end
