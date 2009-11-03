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
#import "EponymCategory.h"
#import "eponyms_touchAppDelegate.h"
#import <sqlite3.h>

static sqlite3_stmt *load_query = nil;
static sqlite3_stmt *mark_accessed_query = nil;
static sqlite3_stmt *toggle_starred_query = nil;


@interface Eponym ()

@property (nonatomic, readwrite, copy) NSString *keywordTitle;

@end


@implementation Eponym

@synthesize eponym_id;
@synthesize title;
@dynamic keywordTitle;
@synthesize text;
@synthesize categories;
@synthesize created;
@synthesize lastedit;
@synthesize lastaccess;
@synthesize starred;
@synthesize eponymCell;


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
- (id) initWithID:(NSUInteger)eid title:(NSString*)ttl delegate:(id)myDelegate
{
	self = [super init];
	if(self) {
		eponym_id = eid;
		self.title = ttl;
		delegate = myDelegate;
	}
    return self;
}

- (void) dealloc
{
	[self unload];
	self.title = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark KVC
- (NSString *) keywordTitle
{
	if (nil == keywordTitle) {
		self.keywordTitle = [self.title stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	}
	return keywordTitle;
}
- (void) setKeywordTitle:(NSString *)newTitle
{
	if (newTitle != keywordTitle) {
		[keywordTitle release];
		keywordTitle = [newTitle copyWithZone:[self zone]];
	}
}
#pragma mark -



#pragma mark loading/unloading
- (void) load
{
	[self markAccessed];
	if(loaded) {
		return;
	}
	
	[[delegate loadedEponyms] addObject:self];
	
	if([delegate database]) {
		
		// load query
		if(!load_query) {
			NSString *textName = @"text_en";
			NSString *categoryTag = @"tag";
			NSString *categoryName = @"category_en";
			const char *qry = [[NSString stringWithFormat:
								@"SELECT created, lastedit, %@, eponym_id, %@, %@, starred FROM eponyms LEFT JOIN category_eponym_linker USING (eponym_id) LEFT JOIN categories USING (category_id) WHERE eponym_id = ?",
								textName,
								categoryTag,
								categoryName] UTF8String];
			if(SQLITE_OK != sqlite3_prepare_v2([delegate database], qry, -1, &load_query, NULL)) {
				NSAssert1(0, @"Error: failed to prepare load_query: '%s'.", sqlite3_errmsg([delegate database]));
			}
		}
		
		NSMutableArray *newCategoriesArr = [[NSMutableArray alloc] initWithCapacity:2];
		NSInteger rows = 0;
		
		// Complete and execute the query
		sqlite3_bind_int(load_query, 1, eponym_id);
		while (SQLITE_ROW == sqlite3_step(load_query)) {
			if (0 == rows) {
				double createdEpoch = sqlite3_column_double(load_query, 0);
				self.created = (createdEpoch > 10.0) ? [NSDate dateWithTimeIntervalSince1970:createdEpoch] : nil;
				double updatedEpoch = sqlite3_column_double(load_query, 1);
				self.lastedit = (updatedEpoch > 10.0) ? [NSDate dateWithTimeIntervalSince1970:updatedEpoch] : nil;
				char *textStr = (char *)sqlite3_column_text(load_query, 2);
				self.text = textStr ? [NSString stringWithUTF8String:textStr] : @"";
			}
			
			NSInteger categoryId = sqlite3_column_int(load_query, 3);
			char *categoryTagStr = (char *)sqlite3_column_text(load_query, 4);
			char *categoryNameStr = (char *)sqlite3_column_text(load_query, 5);
			EponymCategory *myCat = [EponymCategory eponymCategoryWithID:categoryId
																	 tag:[NSString stringWithUTF8String:categoryTagStr]
																   title:[NSString stringWithUTF8String:categoryNameStr]
														  whereStatement:nil];
			[newCategoriesArr addObject:myCat];
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
}

- (void) unload
{
	[[delegate loadedEponyms] removeObject:self];
	
	self.text = nil;
	self.categories = nil;
	self.created = nil;
	self.lastedit = nil;
	self.lastaccess = nil;
	
	loaded = NO;
}
#pragma mark -



#pragma mark Other
- (void) toggleStarred
{
	if([delegate database]) {
		if(!toggle_starred_query) {
			const char *qry = "UPDATE eponyms SET starred = ? WHERE eponym_id = ?";
			if(sqlite3_prepare_v2([delegate database], qry, -1, &toggle_starred_query, NULL) != SQLITE_OK) {
				NSAssert1(0, @"Error: failed to prepare toggle_starred_query: '%s'.", sqlite3_errmsg([delegate database]));
			}
		}
		
		// bind
		sqlite3_bind_int(toggle_starred_query, 1, starred ? 0 : 1);
		sqlite3_bind_int(toggle_starred_query, 2, eponym_id);
		
		// execute
		if(SQLITE_DONE != sqlite3_step(toggle_starred_query)) {
			NSAssert1(0, @"Error: failed to execute toggle_starred_query: '%s'.", sqlite3_errmsg([delegate database]));
		}
		sqlite3_reset(toggle_starred_query);
		starred = !starred;
	}
}

- (void) markAccessed
{
	if([delegate database]) {
		if(!mark_accessed_query) {
			const char *qry = "UPDATE eponyms SET lastaccess = ? WHERE eponym_id = ?";
			if(sqlite3_prepare_v2([delegate database], qry, -1, &mark_accessed_query, NULL) != SQLITE_OK) {
				NSAssert1(0, @"Error: failed to prepare mark_accessed_query: '%s'.", sqlite3_errmsg([delegate database]));
			}
		}
		
		sqlite3_bind_int(mark_accessed_query, 1, [[NSDate date] timeIntervalSince1970]);
		sqlite3_bind_int(mark_accessed_query, 2, eponym_id);
		
		if(SQLITE_DONE != sqlite3_step(mark_accessed_query)) {
			NSAssert1(0, @"Error: failed to execute mark_accessed_query: '%s'.", sqlite3_errmsg([delegate database]));
		}
		sqlite3_reset(mark_accessed_query);
	}
}



@end
