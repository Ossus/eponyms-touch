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
	sqlite3 *database;
	sqlite3 *memory_database;
	
	NSUInteger updateAction;				// 1 = check, 2 = download and install
}


@property (nonatomic, unsafe_unretained) id<EponymUpdaterDelegate> delegate;
@property (nonatomic, unsafe_unretained) InfoViewController<EponymUpdaterDelegate> *viewController;
@property (nonatomic, assign) NSUInteger updateAction;

@property (nonatomic, assign) BOOL newEponymsAvailable;
@property (nonatomic, strong) NSString *statusMessage;

// Downloading
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL downloadFailed;
@property (nonatomic, strong) NSURL *eponymUpdateCheckURL;
@property (nonatomic, strong) NSURL *eponymXMLURL;

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) long long expectedContentLength;

@property (nonatomic, strong) NSURLConnection *myConnection;
@property (nonatomic, strong) NSMutableData *receivedData;

// Parsing
@property (nonatomic, assign) BOOL isParsing;
@property (nonatomic, assign) BOOL mustAbortImport;
@property (nonatomic, assign) BOOL parseFailed;
@property (nonatomic, assign) NSInteger eponymCheck_eponymUpdateTime;
@property (nonatomic, assign) NSInteger eponymCheckFileSize;

@property (nonatomic, assign) NSUInteger readyToLoadNumEponyms;

@property (nonatomic, strong) NSDate *eponymCreationDate;
@property (nonatomic, strong) NSMutableDictionary *currentlyParsedNode;
@property (nonatomic, strong) NSMutableString *contentOfCurrentXMLNode;
@property (nonatomic, strong) NSMutableArray *categoriesOfCurrentEponym;
@property (nonatomic, strong) NSMutableDictionary *categoriesAlreadyInserted;
@property (nonatomic, assign) NSUInteger numEponymsParsed;

- (id) initWithDelegate:(id) myDelegate;
- (void) startUpdaterAction;
- (void) createEponymsWithData:(NSData *)XMLData;

@end
