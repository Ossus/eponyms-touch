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
#ifdef SHOW_ADS
#	import <iSoma/SOMAAdListenerProtocol.h>
#endif

@class Eponym;
@class MCTextView;
@class PPHintableLabel;


@interface EponymViewController : UIViewController <UIScrollViewDelegate
#ifdef SHOW_ADS
													, SOMAAdListenerProtocol
#endif
	>
{
	BOOL viewIsVisible;
#ifdef SHOW_ADS
	NSTimeInterval adsAreRefractoryUntil;			// timestamp until we allow loading a new ad
#endif
}

@property (nonatomic, strong) Eponym *eponym;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonStarredItem;
@property (nonatomic, strong) UIBarButtonItem *rightBarButtonNotStarredItem;

@property (nonatomic, strong) UILabel *eponymTitleLabel;
@property (nonatomic, strong) MCTextView *eponymTextView;
@property (nonatomic, strong) PPHintableLabel *eponymCategoriesLabel;
@property (nonatomic, strong) UILabel *dateCreatedLabel;
@property (nonatomic, strong) UILabel *dateUpdatedLabel;

@property (nonatomic, assign) EPLearningMode displayNextEponymInLearningMode;
@property (nonatomic, strong) UIButton *randomNoTitleEponymButton;
@property (nonatomic, strong) UIButton *randomNoTextEponymButton;
@property (nonatomic, strong) UIButton *revealButton;

- (void)setEponym:(Eponym *)newEponym animated:(BOOL)animated;

- (void)toggleEponymStarred:(id)sender;
- (void)indicateEponymStarredStatus;

- (IBAction)reveal:(id)sender;


@end
