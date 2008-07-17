//
//  Eponym.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 06.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Eponym Object for eponyms-touch
//  


#import <Foundation/Foundation.h>
#import <sqlite3.h>


@interface Eponym : NSObject {
	sqlite3 *database;
	
	// Primary key
	NSUInteger eponym_id;
	
	// Eponym Attributes.
	NSString *title;
	NSDate *created;
	NSDate *lastedit;
	NSString *text;
	NSArray *categories;
	
	BOOL loaded;
}
	
// KVC
@property (readonly, nonatomic) NSUInteger eponym_id;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSDate *created;
@property (copy, nonatomic) NSDate *lastedit;
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSArray *categories;

// Finalize (delete) all of the SQLite compiled queries.
+ (void) finalizeQueries;

// Init the Eponym with the desired key
- (id) initWithID:(NSUInteger) eid title:(NSString*) ttl fromDatabase:(sqlite3 *)db;

// Loading and unloading. Everything but key and title are wiped from memory on unload
- (void) load;
- (void) unload;

@end
