//
//  UIViewController+PPSubclassing.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 6/7/10.
//  Copyright 2010 Institute Of Immunology. All rights reserved.
//

#import "UIViewController+PPSubclassing.h"


@implementation UIViewController (PPSubclassing)

- (void) setParentController:(UIViewController *)newParent
{
	[self setValue:newParent forKey:@"_parentViewController"];
}

@end
