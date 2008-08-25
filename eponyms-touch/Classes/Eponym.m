//
//  Eponym.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 06.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Eponym Object for eponyms-touch
//  


#import "Eponym.h"

static sqlite3_stmt *load_query = nil;
static sqlite3_stmt *mark_accessed_query = nil;
static sqlite3_stmt *toggle_starred_query = nil;


@implementation Eponym

@synthesize eponym_id, title, text, categories, created, lastedit, lastaccess, starred, eponymCell;


// finalizes the compiled queries (needed before quitting)
+ (void) finalizeQueries;
{
	if(load_query) {
		sqlite3_finalize(load_query);
		load_query = nil;
	}
	if(mark_accessed_query) {
		sqlite3_finalize(mark_accessed_query);
		mark_accessed_query = nil;
	}
	if(toggle_starred_query) {
		sqlite3_finalize(toggle_starred_query);
		toggle_starred_query = nil;
	}
}

// Init the Eponym with the desired key
- (id) initWithID:(NSUInteger) eid title:(NSString*) ttl fromDatabase:(sqlite3 *)db
{
	self = [super init];
	if(self) {
		eponym_id = eid;
		database = db;
		self.title = ttl;
	}
    return self;
}

- (void) dealloc
{
	[self unload];
	[title release];		title = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark loading/unloading
- (void) load
{
	[self markAccessed];
	if(loaded) {
		return;
	}
	
	// load query
	if(!load_query) {
		NSString *textName = @"text_en";
		NSString *categoryName = @"tag";
		const char *qry = [[NSString stringWithFormat:@"SELECT created, lastedit, %@, %@, starred FROM eponyms LEFT JOIN category_eponym_linker USING (eponym_id) LEFT JOIN categories USING (category_id) WHERE eponym_id = ?", textName, categoryName] UTF8String];
		if(SQLITE_OK != sqlite3_prepare_v2(database, qry, -1, &load_query, NULL)) {
			NSAssert1(0, @"Error: failed to prepare load_query: '%s'.", sqlite3_errmsg(database));
		}
	}
	
	NSMutableArray *newCategoriesArr = [[NSMutableArray alloc] initWithCapacity:2];
	NSInteger rows = 0;
	
	// Complete and execute the query
	sqlite3_bind_int(load_query, 1, eponym_id);
	while(SQLITE_ROW == sqlite3_step(load_query)) {
		if(0 == rows) {
			double createdEpoch = sqlite3_column_double(load_query, 0);
			self.created = (createdEpoch > 10.0) ? [NSDate dateWithTimeIntervalSince1970:createdEpoch] : nil;
			double updatedEpoch = sqlite3_column_double(load_query, 1);
			self.lastedit = (updatedEpoch > 10.0) ? [NSDate dateWithTimeIntervalSince1970:updatedEpoch] : nil;
			char *textStr = (char *)sqlite3_column_text(load_query, 2);
			self.text = textStr ? [NSString stringWithUTF8String:textStr] : @"";
		}
		
		char *categoryStr = (char *)sqlite3_column_text(load_query, 3);
		[newCategoriesArr addObject:(categoryStr ? [NSString stringWithUTF8String:categoryStr] : @"")];
		
		rows++;
	}
	
	// eponym not found
	if(rows < 1) {
		self.created = nil;
		self.lastedit = nil;
		self.text = @"-";
	}
	
	self.categories = newCategoriesArr;
	[newCategoriesArr release];
	
	sqlite3_reset(load_query);
	loaded = YES;
}

- (void) unload
{
	[created release];		created = nil;
	[lastedit release];		lastedit = nil;
	[text release];			text = nil;
	[categories release];	categories = nil;
	
	loaded = NO;
}
#pragma mark -



#pragma mark Other
- (void) toggleStarred
{
	if(!toggle_starred_query) {
		const char *qry = "UPDATE eponyms SET starred = ? WHERE eponym_id = ?";
		if(sqlite3_prepare_v2(database, qry, -1, &toggle_starred_query, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare toggle_starred_query: '%s'.", sqlite3_errmsg(database));
		}
	}
	
	// bind
	sqlite3_bind_int(toggle_starred_query, 1, starred ? 0 : 1);
	sqlite3_bind_int(toggle_starred_query, 2, eponym_id);
	
	// execute
	if(SQLITE_DONE != sqlite3_step(toggle_starred_query)) {
		NSAssert1(0, @"Error: failed to execute toggle_starred_query: '%s'.", sqlite3_errmsg(database));
	}
	sqlite3_reset(toggle_starred_query);
	starred = !starred;
}

- (void) markAccessed
{
	if(!mark_accessed_query) {
		const char *qry = "UPDATE eponyms SET lastaccess = ? WHERE eponym_id = ?";
		if(sqlite3_prepare_v2(database, qry, -1, &mark_accessed_query, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare mark_accessed_query: '%s'.", sqlite3_errmsg(database));
		}
	}
	
	sqlite3_bind_int(mark_accessed_query, 1, [[NSDate date] timeIntervalSince1970]);
	sqlite3_bind_int(mark_accessed_query, 2, eponym_id);
	
	if(SQLITE_DONE != sqlite3_step(mark_accessed_query)) {
		NSAssert1(0, @"Error: failed to execute mark_accessed_query: '%s'.", sqlite3_errmsg(database));
	}
	sqlite3_reset(mark_accessed_query);
}



@end
