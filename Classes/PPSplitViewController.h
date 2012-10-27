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
	
	BOOL useCustomLeftTitleBar;						// YES by default
	BOOL useCustomRightTitleBar;					// YES by default
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

@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) UIViewController *rightViewController;
@property (nonatomic, strong) UIViewController *tabViewController;
@property (nonatomic, strong) UIImage *logo;

@property (nonatomic, assign) BOOL usesFullLandscapeWidth;

@property (nonatomic, assign) BOOL useCustomLeftTitleBar;
@property (nonatomic, assign) BOOL useCustomRightTitleBar;
@property (nonatomic, readonly, strong) UINavigationBar *leftTitleBar;
@property (nonatomic, readonly, strong) UINavigationBar *rightTitleBar;


@end
