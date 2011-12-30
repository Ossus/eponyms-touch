//
//  PPHintViewContainer.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 20.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPHintView;


@interface PPHintViewContainer : UIView {
	PPHintView *hint;
}

@property (nonatomic, assign) PPHintView *hint;


@end
