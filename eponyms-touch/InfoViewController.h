//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  Copyright 2008 home sweet home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>


@class EponymUpdater;


@interface InfoViewController : UIViewController <UIAlertViewDelegate> {
	id delegate;
	sqlite3 *database;
	
	EponymUpdater *myUpdater;
	BOOL needToReloadEponyms;
	BOOL firstTimeLaunch;
	BOOL newEponymsAvailable;
	BOOL iAmUpdating;
	
	NSInteger lastEponymCheck;
	NSInteger lastEponymUpdate;
	NSInteger usingEponymsOf;
	NSUInteger readyToLoadNumEponyms;
	
	IBOutlet UILabel *versionLabel;
	IBOutlet UILabel *usingEponymsLabel;
	IBOutlet UILabel *lastCheckLabel;
	IBOutlet UILabel *lastUpdateLabel;
	IBOutlet UITextView *infoTextView;
	
	IBOutlet UIButton *updateButton;
	IBOutlet UIButton *projectWebsiteButton;
	IBOutlet UIButton *eponymsDotNetButton;
	
	IBOutlet UILabel *progressText;
	IBOutlet UIProgressView *progressView;
	
	NSDictionary *infoPlistDict;
	NSURL *projectWebsiteURL;
	NSURL *eponymUpdateCheckURL;
	NSURL *eponymXMLURL;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, assign) BOOL needToReloadEponyms;
@property (nonatomic, assign) BOOL firstTimeLaunch;
@property (nonatomic, assign) BOOL newEponymsAvailable;
@property (nonatomic, assign) BOOL iAmUpdating;

@property (nonatomic, retain) EponymUpdater *myUpdater;
@property (nonatomic, assign) NSInteger lastEponymCheck;
@property (nonatomic, assign) NSInteger lastEponymUpdate;
@property (nonatomic, assign) NSInteger usingEponymsOf;
@property (nonatomic, assign) NSUInteger readyToLoadNumEponyms;

@property (nonatomic, readonly) UILabel *progressText;
@property (nonatomic, readonly) UIProgressView *progressView;
@property (nonatomic, readonly) UIButton *updateButton;

@property (nonatomic, retain) NSDictionary *infoPlistDict;
@property (nonatomic, retain) NSURL *projectWebsiteURL;
@property (nonatomic, retain) NSURL *eponymUpdateCheckURL;
@property (nonatomic, retain) NSURL *eponymXMLURL;

- (void) updateLabelsWithDateForLastCheck:(NSDate *) lastCheck lastUpdate:(NSDate *) lastUpdate usingEponyms:(NSDate *) usingEponyms;
- (void) dismissMe:(id) sender;

- (void) setUpdateButtonTitle:(NSString *) title;
- (void) setUpdateButtonTitleColor:(UIColor *) color;
- (void) setStatusMessage:(NSString *) message;
- (void) setProgress:(CGFloat) progress;

// Online Access
- (IBAction) performUpdateAction:(id) sender;
- (IBAction) openProjectWebsite:(id) sender;
- (IBAction) openEponymsDotNet:(id) sender;

@end
