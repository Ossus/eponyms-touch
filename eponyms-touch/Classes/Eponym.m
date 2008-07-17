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


@implementation Eponym

@synthesize eponym_id, title, created, lastedit, text, categories;


// finalizes the compiled queries (needed before quitting)
+ (void) finalizeQueries;
{
	if(load_query) {
		sqlite3_finalize(load_query);
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
	NSLog(@"eponym dealloc");
	[self unload];
	[title release];		title = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark loading/unloading
- (void) load
{
	NSLog(@"want to load id %i, retainCount %i", eponym_id, [self retainCount]);
	if(loaded) {
		return;
	}
	
	// load query
	if(load_query == nil) {
		NSString *categoryName = @"category_en";
		const char *qry = [[NSString stringWithFormat:@"SELECT created, lastedit, text, %@ FROM eponyms LEFT JOIN category_eponym_linker USING (eponym_id) LEFT JOIN categories USING (category_id) WHERE eponym_id = ?", categoryName] UTF8String];
		if(sqlite3_prepare_v2(database, qry, -1, &load_query, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare query: '%s'.", sqlite3_errmsg(database));
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

@end
