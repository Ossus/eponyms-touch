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

@class Eponym;
@class EponymTextView;


@interface EponymViewController : UIViewController {
	id delegate;
	Eponym *eponymToBeShown;
	
	UIScrollView *eponymView;
	UILabel *eponymTitleLabel;
	EponymTextView *eponymTextView;
	UILabel *eponymCategoriesLabel;
	UILabel *dateCreatedLabel;
	UILabel *dateUpdatedLabel;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) Eponym *eponymToBeShown;

@property (nonatomic, retain) UIScrollView *eponymView;
@property (nonatomic, retain) UILabel *eponymTitleLabel;
@property (nonatomic, retain) EponymTextView *eponymTextView;
@property (nonatomic, retain) UILabel *eponymCategoriesLabel;
@property (nonatomic, retain) UILabel *dateCreatedLabel;
@property (nonatomic, retain) UILabel *dateUpdatedLabel;


@end
