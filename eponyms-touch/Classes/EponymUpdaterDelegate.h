//
//  TouchTableViewDelegate.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 28.08.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Protocol for the delegate of the EponymUpdater
// 

#import <UIKit/UIKit.h>
@class EponymUpdater;

@protocol EponymUpdaterDelegate <NSObject>

- (void) updaterDidStartAction:(EponymUpdater *)updater;
- (void) updater:(EponymUpdater *)updater didEndActionSuccessful:(BOOL)success;

@optional

- (void) updater:(EponymUpdater *)updater progress:(CGFloat)progress;

@end
