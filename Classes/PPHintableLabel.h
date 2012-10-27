//
//  PPHintableLabel.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 25.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPHintView;


@interface PPHintableLabel : UILabel

@property (nonatomic, copy) NSString *hintText;
@property (nonatomic, strong) UIColor *readyColor;					// the color when we are ready to show the hint, by default "Ocean" rgb(0,25%,50%)
@property (nonatomic, strong) UIColor *activeColor;					// the color when we are showing the hint, by default rgb(0,40%,80%)

@property (nonatomic, readonly, unsafe_unretained) PPHintView *hintViewDisplayed;


- (void)hintView:(PPHintView *)hintView didDisplayAnimated:(BOOL)animated;
- (void)hintView:(PPHintView *)hintView didHideAnimated:(BOOL)animated;


@end
