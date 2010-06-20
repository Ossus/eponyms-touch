//
//  EponymUpdater.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 08.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Updater object that downloads the eponym XML and fills the SQLite database
//  for eponyms-touch
//  


#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "EponymUpdaterDelegate.h"

@class InfoViewController;


@interface EponymUpdater : NSObject <NSXMLParserDelegate> {
	id<EponymUpdaterDelegate> delegate;
	InfoViewController<EponymUpdaterDelegate> *viewController;
	
	sqlite3 *database;
	sqlite3 *memory_database;
	
	BOOL newEponymsAvailable;
	NSUInteger updateAction;				// 1 = check, 2 = download and install
	NSString *statusMessage;
	
	// Downloading
	BOOL isDownloading;
	BOOL downloadFailed;
	NSURL *eponymUpdateCheckURL;
	NSURL *eponymXMLURL;
	NSInteger statusCode;					// Server response code
	long long expectedContentLength;
	
	NSURLConnection *myConnection;
	NSMutableData *receivedData;
	
	// Parsing
	BOOL isParsing;
	BOOL mustAbortImport;
	BOOL parseFailed;
	NSAutoreleasePool *innerPool;
	NSInteger eponymCheck_eponymUpdateTime;
	NSInteger eponymCheckFileSize;
	
	NSUInteger readyToLoadNumEponyms;
	
	NSDate *eponymCreationDate;
	NSMutableDictionary *currentlyParsedNode;
	NSMutableString *contentOfCurrentXMLNode;
	NSMutableArray *categoriesOfCurrentEponym;
	NSMutableDictionary *categoriesAlreadyInserted;		// key = category, value = NSNumber containing the category_id
	NSUInteger numEponymsParsed;
}


@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) InfoViewController *viewController;
@property (nonatomic, assign) NSUInteger updateAction;

@property (nonatomic, assign) BOOL newEponymsAvailable;
@property (nonatomic, retain) NSString *statusMessage;

// Downloading
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL downloadFailed;
@property (nonatomic, retain) NSURL *eponymUpdateCheckURL;
@property (nonatomic, retain) NSURL *eponymXMLURL;

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) long long expectedContentLength;

@property (nonatomic, retain) NSURLConnection *myConnection;
@property (nonatomic, retain) NSMutableData *receivedData;

// Parsing
@property (nonatomic, assign) BOOL isParsing;
@property (nonatomic, assign) BOOL mustAbortImport;
@property (nonatomic, assign) BOOL parseFailed;
@property (nonatomic, assign) NSInteger eponymCheck_eponymUpdateTime;
@property (nonatomic, assign) NSInteger eponymCheckFileSize;

@property (nonatomic, assign) NSUInteger readyToLoadNumEponyms;

@property (nonatomic, retain) NSDate *eponymCreationDate;
@property (nonatomic, retain) NSMutableDictionary *currentlyParsedNode;
@property (nonatomic, retain) NSMutableString *contentOfCurrentXMLNode;
@property (nonatomic, retain) NSMutableArray *categoriesOfCurrentEponym;
@property (nonatomic, retain) NSMutableDictionary *categoriesAlreadyInserted;
@property (nonatomic, assign) NSUInteger numEponymsParsed;

- (id) initWithDelegate:(id) myDelegate;
- (void) startUpdaterAction;
- (void) createEponymsWithData:(NSData *)XMLData;

@end
