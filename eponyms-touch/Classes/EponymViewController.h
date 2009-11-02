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
#import "GADAdViewController.h"
@class Eponym;
@class MCTextView;


@interface EponymViewController : UIViewController <GADAdViewControllerDelegate> {
	id delegate;
	Eponym *eponymToBeShown;
	
	UIBarButtonItem *rightBarButtonStarredItem;
	UIBarButtonItem *rightBarButtonNotStarredItem;
	
	UILabel *eponymTitleLabel;
	MCTextView *eponymTextView;
	UILabel *eponymCategoriesLabel;
	UILabel *dateCreatedLabel;
	UILabel *dateUpdatedLabel;
	
	GADAdViewController *adController;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) Eponym *eponymToBeShown;

@property (nonatomic, retain) UIBarButtonItem *rightBarButtonStarredItem;
@property (nonatomic, retain) UIBarButtonItem *rightBarButtonNotStarredItem;

@property (nonatomic, retain) UILabel *eponymTitleLabel;
@property (nonatomic, retain) MCTextView *eponymTextView;
@property (nonatomic, retain) UILabel *eponymCategoriesLabel;
@property (nonatomic, retain) UILabel *dateCreatedLabel;
@property (nonatomic, retain) UILabel *dateUpdatedLabel;

@property (nonatomic, readonly, retain) GADAdViewController *adController;

- (void) toggleEponymStarred;


@end
