//
//  EponymViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the eponym view for eponyms-touch
//  


#import <UIKit/UIKit.h>
#ifdef SHOW_GOOGLE_ADS
#import "GADAdViewController.h"
#endif
@class Eponym;
@class MCTextView;
@class PPHintableLabel;


@interface EponymViewController : UIViewController <UIScrollViewDelegate
#ifdef SHOW_GOOGLE_ADS
													, GADAdViewControllerDelegate
#endif
	> {
	id delegate;
	Eponym *eponymToBeShown;
	BOOL viewIsVisible;
	
	UIBarButtonItem *rightBarButtonStarredItem;
	UIBarButtonItem *rightBarButtonNotStarredItem;
	
	UILabel *eponymTitleLabel;
	MCTextView *eponymTextView;
	PPHintableLabel *eponymCategoriesLabel;
	UILabel *dateCreatedLabel;
	UILabel *dateUpdatedLabel;
	
	UIButton *revealButton;	
	NSInteger displayNextEponymInLearningMode;		// -1 = title hidden, 0 = normal, 1 = eponym hidden
#ifdef SHOW_GOOGLE_ADS	
	BOOL adIsLoading;
	BOOL adDidLoad;
	GADAdViewController *adController;
	NSTimeInterval adsAreRefractoryUntil;			// timestamp until we allow loading a new ad
#endif
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) Eponym *eponymToBeShown;

@property (nonatomic, retain) UIBarButtonItem *rightBarButtonStarredItem;
@property (nonatomic, retain) UIBarButtonItem *rightBarButtonNotStarredItem;

@property (nonatomic, retain) UILabel *eponymTitleLabel;
@property (nonatomic, retain) MCTextView *eponymTextView;
@property (nonatomic, retain) PPHintableLabel *eponymCategoriesLabel;
@property (nonatomic, retain) UILabel *dateCreatedLabel;
@property (nonatomic, retain) UILabel *dateUpdatedLabel;

@property (nonatomic, retain) UIButton *revealButton;
@property (nonatomic, assign) NSInteger displayNextEponymInLearningMode;
#ifdef SHOW_GOOGLE_ADS
@property (nonatomic, readonly, retain) GADAdViewController *adController;
#endif

- (void) toggleEponymStarred:(id)sender;
- (void) indicateEponymStarredStatus;

- (void) reveal:(id)sender;


@end
