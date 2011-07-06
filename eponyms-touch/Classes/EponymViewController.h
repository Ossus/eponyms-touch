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
#import "GADBannerView.h"
#endif
@class Eponym;
@class MCTextView;
@class PPHintableLabel;


@interface EponymViewController : UIViewController <UIScrollViewDelegate
#ifdef SHOW_GOOGLE_ADS
													, GADBannerViewDelegate
#endif
	>
{
	Eponym *eponymToBeShown;
	BOOL viewIsVisible;
	
	UIBarButtonItem *rightBarButtonStarredItem;
	UIBarButtonItem *rightBarButtonNotStarredItem;
	
	UILabel *eponymTitleLabel;
	MCTextView *eponymTextView;
	PPHintableLabel *eponymCategoriesLabel;
	UILabel *dateCreatedLabel;
	UILabel *dateUpdatedLabel;
	
	EPLearningMode displayNextEponymInLearningMode;
	UIButton *randomNoTitleEponymButton;
	UIButton *randomNoTextEponymButton;
	UIButton *revealButton;
	
#ifdef SHOW_GOOGLE_ADS
	CGSize adSize;
	BOOL adIsLoading;
	BOOL adDidLoadForThisEponym;
	GADBannerView *adView;
	NSTimeInterval adsAreRefractoryUntil;			// timestamp until we allow loading a new ad
#endif
}

@property (nonatomic, retain) Eponym *eponymToBeShown;

@property (nonatomic, retain) UIBarButtonItem *rightBarButtonStarredItem;
@property (nonatomic, retain) UIBarButtonItem *rightBarButtonNotStarredItem;

@property (nonatomic, retain) UILabel *eponymTitleLabel;
@property (nonatomic, retain) MCTextView *eponymTextView;
@property (nonatomic, retain) PPHintableLabel *eponymCategoriesLabel;
@property (nonatomic, retain) UILabel *dateCreatedLabel;
@property (nonatomic, retain) UILabel *dateUpdatedLabel;

@property (nonatomic, assign) EPLearningMode displayNextEponymInLearningMode;
@property (nonatomic, retain) UIButton *randomNoTitleEponymButton;
@property (nonatomic, retain) UIButton *randomNoTextEponymButton;
@property (nonatomic, retain) UIButton *revealButton;

#ifdef SHOW_GOOGLE_ADS
@property (nonatomic, readonly, retain) GADBannerView *adView;
#endif

- (void) toggleEponymStarred:(id)sender;
- (void) indicateEponymStarredStatus;

- (void) reveal:(id)sender;


@end
