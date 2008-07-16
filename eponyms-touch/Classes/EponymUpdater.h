//
//  EponymUpdater.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 08.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>


@interface EponymUpdater : NSObject {
	id delegate;
	sqlite3 *database;
	sqlite3 *memory_database;
	
	NSUInteger updateAction;				// 1 = check, 2 = download and install
	NSInteger statusCode;					// Server response code
	long long expectedContentLength;		
	BOOL mustAbortImport;
	
	NSURLConnection *myConnection;
	NSMutableData *receivedData;
	
	// Parsing
	NSInteger eponymCheckLastUpdateTime;
	NSInteger eponymCheckFileSize;
	NSUInteger eponymCheckNumEponyms;
	
	NSUInteger readyToLoadNumEponyms;
	NSString *eponymCreationDate;
	NSMutableDictionary *currentlyParsedEponym;
	NSMutableString *contentOfCurrentXMLNode;
	NSMutableArray *categoriesOfCurrentEponym;
	NSMutableDictionary *categoriesAlreadyInserted;		// key = category, value = NSNumber containing the category_id
	NSUInteger numEponymsParsed;
}


@property (nonatomic, retain) id delegate;
@property (nonatomic, assign) NSUInteger updateAction;

// Downloading
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) long long expectedContentLength;
@property (nonatomic, assign) BOOL mustAbortImport;

@property (nonatomic, retain) NSURLConnection *myConnection;
@property (nonatomic, retain) NSMutableData *receivedData;
- (void) startDownloadingWithAction:(NSUInteger) myAction;

// Parsing
@property (nonatomic, assign) NSInteger eponymCheckLastUpdateTime;
@property (nonatomic, assign) NSInteger eponymCheckFileSize;
@property (nonatomic, assign) NSUInteger eponymCheckNumEponyms;

@property (nonatomic, assign) NSUInteger readyToLoadNumEponyms;
@property (nonatomic, retain) NSString *eponymCreationDate;
@property (nonatomic, retain) NSMutableDictionary *currentlyParsedEponym;
@property (nonatomic, retain) NSMutableString *contentOfCurrentXMLNode;
@property (nonatomic, retain) NSMutableArray *categoriesOfCurrentEponym;
@property (nonatomic, retain) NSMutableDictionary *categoriesAlreadyInserted;
@property (nonatomic, assign) NSUInteger numEponymsParsed;

- (void) createEponymsWithData:(NSData *) XMLData;

@end
