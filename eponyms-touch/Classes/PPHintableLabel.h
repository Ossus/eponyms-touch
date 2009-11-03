//
//  PPHintableLabel.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 25.10.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import <UIKit/UIKit.h>
@class PPHintView;


@interface PPHintableLabel : UILabel {
	NSString *hintText;
	UIColor *oldTextColor;
	PPHintView *hintViewDisplayed;
}

@property (nonatomic, copy) NSString *hintText;
@property (nonatomic, readonly, assign) PPHintView *hintViewDisplayed;


- (void) hintView:(PPHintView *)hintView didDisplayAnimated:(BOOL)animated;
- (void) hintView:(PPHintView *)hintView didHideAnimated:(BOOL)animated;


@end
