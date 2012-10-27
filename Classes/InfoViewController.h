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

@property (nonatomic, unsafe_unretained) AppDelegate *delegate;
@property (nonatomic, assign) BOOL firstTimeLaunch;

@property (nonatomic, assign) NSInteger lastEponymCheck;
@property (nonatomic, assign) NSInteger lastEponymUpdate;
@property (nonatomic, strong) NSDictionary *infoPlistDict;
@property (nonatomic, strong) NSURL *projectWebsiteURL;

@property (nonatomic, strong) IBOutlet UIScrollView *parentView;
@property (nonatomic, strong) UISegmentedControl *tabSegments;

@property (nonatomic, strong) IBOutlet UIView *infoView;
@property (nonatomic, strong) IBOutlet UIView *updatesView;

@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UILabel *usingEponymsLabel;
@property (nonatomic, strong) IBOutlet UIButton *projectWebsiteButton;
@property (nonatomic, strong) IBOutlet UIButton *eponymsDotNetButton;

@property (nonatomic, strong) IBOutlet UILabel *lastCheckLabel;
@property (nonatomic, strong) IBOutlet UILabel *lastUpdateLabel;
@property (nonatomic, strong) IBOutlet UILabel *progressText;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIButton *updateButton;
@property (nonatomic, strong) IBOutlet UISwitch *autocheckSwitch;

- (IBAction)tabChanged:(id)sender;
- (void)updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms;
- (IBAction)dismissMe:(id)sender;

- (void)setUpdateButtonTitle:(NSString *)title;
- (void)setUpdateButtonTitleColor:(UIColor *)color;
- (void)setStatusMessage:(NSString *)message;
- (void)setProgress:(CGFloat) progress;

// Options
- (IBAction)performUpdateAction:(id)sender;
- (IBAction)switchToggled:(id)sender;

// Links
- (IBAction)openProjectWebsite:(id)sender;
- (IBAction)openEponymsDotNet:(id)sender;

- (void)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
- (void)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle;


@end
