//
//  UIViewController+PPSubclassing.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 6/7/10.
//  Copyright 2010 Institute Of Immunology. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (PPSubclassing)

- (void) setParentController:(UIViewController *)newParent;

@end
