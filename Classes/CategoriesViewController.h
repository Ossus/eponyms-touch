//
//  CategoriesViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the categories view for eponyms-touch
//  


#import <UIKit/UIKit.h>
#import "MCTableViewController.h"
@class AppDelegate;


@interface CategoriesViewController : MCTableViewController

@property (nonatomic, unsafe_unretained) AppDelegate *delegate;
@property (nonatomic, strong) NSArray *categoryArrayCache;


@end
