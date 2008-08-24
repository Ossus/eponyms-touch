//
//  EponymTextView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 24.08.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITextView subclass that draws rounded corners for eponyms-touch
// 

#import <UIKit/UIKit.h>
@class TouchTableView;

@protocol TouchTableViewDelegate <NSObject>

- (void) tableView:(TouchTableView *)tableView didDoubleTapRowAtIndexPath:(NSIndexPath *)indexPath;

@end
