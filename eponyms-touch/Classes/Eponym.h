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


@interface Eponym : NSObject {
	id delegate;
	
	// Primary key
	NSUInteger eponym_id;
	
	// Eponym Attributes
	NSString *title;
	NSString *keywordTitle;			// the title ready to be used as a keyword
	NSString *text;
	NSArray *categories;
	NSDate *created;
	NSDate *lastedit;
	NSDate *lastaccess;
	NSUInteger starred;
	
	BOOL loaded;
}
	
// KVC
@property (readonly, nonatomic) NSUInteger eponym_id;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic, readonly) NSString *keywordTitle;
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSArray *categories;
@property (copy, nonatomic) NSDate *created;
@property (copy, nonatomic) NSDate *lastedit;
@property (copy, nonatomic) NSDate *lastaccess;
@property (nonatomic, assign) NSUInteger starred;

// Finalize (delete) all of the SQLite compiled queries.
+ (void) finalizeQueries;

// Init the Eponym with the desired key
- (id) initWithID:(NSUInteger) eid title:(NSString*) ttl delegate:(id)myDelegate;

// Loading and unloading. Everything but key and title are wiped from memory on unload
- (void) load;
- (void) unload;

- (void) toggleStarred;
- (void) markAccessed;

@end
