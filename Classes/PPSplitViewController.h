//
//  PPSplitViewController.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 21.04.10.
//  Copyright 2010 Institute Of Immunology. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PPSplitViewController : UIViewController {
	@private
	BOOL isLandscape;
	BOOL wasLandscape;								// the status before the current animation
	BOOL trackRotationAnimation;
}

@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) UIViewController *rightViewController;
@property (nonatomic, strong) UIViewController *tabViewController;
@property (nonatomic, strong) UIImage *logo;

@property (nonatomic, assign) BOOL usesFullLandscapeWidth;				// YES by default. if NO adds a margin to the left and right

@property (nonatomic, assign) BOOL useCustomLeftTitleBar;				// YES by default
@property (nonatomic, assign) BOOL useCustomRightTitleBar;				// YES by default
@property (nonatomic, readonly, strong) UINavigationBar *leftTitleBar;
@property (nonatomic, readonly, strong) UINavigationBar *rightTitleBar;


@end
