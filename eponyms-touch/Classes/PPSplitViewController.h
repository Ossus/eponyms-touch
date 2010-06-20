//
//  PPSplitViewController.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 21.04.10.
//  Copyright 2010 Institute Of Immunology. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PPSplitViewController : UIViewController {
	UIViewController *leftViewController;
	UIViewController *rightViewController;
	UIViewController *tabViewController;
	UIImage *logo;
	
	BOOL usesFullLandscapeWidth;					// YES by default. if NO adds a margin to the left and right
	
	UINavigationBar *leftTitleBar;
	UINavigationBar *rightTitleBar;
	
	@private
	UIView *containerView;
	UIView *leftView;
	UIView *rightView;
	UIView *tabView;
	UIImageView *logoView;
	
	BOOL isLandscape;
	BOOL wasLandscape;								// the status before the current animation
	BOOL trackRotationAnimation;
}

@property (nonatomic, retain) UIViewController *leftViewController;
@property (nonatomic, retain) UIViewController *rightViewController;
@property (nonatomic, retain) UIViewController *tabViewController;
@property (nonatomic, retain) UIImage *logo;

@property (nonatomic, assign) BOOL usesFullLandscapeWidth;

@property (nonatomic, readonly, retain) UINavigationBar *leftTitleBar;
@property (nonatomic, readonly, retain) UINavigationBar *rightTitleBar;


@end
