//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller for the info screen for eponyms-touch
//  


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "EponymUpdaterDelegate.h"
@class AppDelegate;



@interface InfoViewController : UIViewController <UIAlertViewDelegate, EponymUpdaterDelegate> {
	BOOL askingToAbortImport;
}

@property (nonatomic, assign) AppDelegate *delegate;
@property (nonatomic, assign) BOOL firstTimeLaunch;

@property (nonatomic, assign) NSInteger lastEponymCheck;
@property (nonatomic, assign) NSInteger lastEponymUpdate;
@property (nonatomic, retain) NSDictionary *infoPlistDict;
@property (nonatomic, retain) NSURL *projectWebsiteURL;

@property (nonatomic, retain) IBOutlet UIScrollView *parentView;
@property (nonatomic, retain) UISegmentedControl *tabSegments;

@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIView *updatesView;

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *usingEponymsLabel;
@property (nonatomic, retain) IBOutlet UIButton *projectWebsiteButton;
@property (nonatomic, retain) IBOutlet UIButton *eponymsDotNetButton;

@property (nonatomic, retain) IBOutlet UILabel *lastCheckLabel;
@property (nonatomic, retain) IBOutlet UILabel *lastUpdateLabel;
@property (nonatomic, retain) IBOutlet UILabel *progressText;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIButton *updateButton;
@property (nonatomic, retain) IBOutlet UISwitch *autocheckSwitch;

- (IBAction) tabChanged:(id)sender;
- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms;
- (IBAction) dismissMe:(id)sender;

- (void) setUpdateButtonTitle:(NSString *)title;
- (void) setUpdateButtonTitleColor:(UIColor *)color;
- (void) setStatusMessage:(NSString *)message;
- (void) setProgress:(CGFloat) progress;

// Options
- (IBAction) performUpdateAction:(id)sender;
- (IBAction) switchToggled:(id)sender;

// Links
- (IBAction) openProjectWebsite:(id)sender;
- (IBAction) openEponymsDotNet:(id)sender;

- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle;

@end