//
//  PPHintViewContainer.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 20.10.09.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//

#import <UIKit/UIKit.h>
@class PPHintView;


@interface PPHintViewContainer : UIView {
	PPHintView *hint;
}

@property (nonatomic, assign) PPHintView *hint;


@end
