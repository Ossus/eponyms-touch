//
//  EponymTextView.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 15.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EponymTextView : UITextView {
	CGFloat borderWidth;
	CGFloat borderRadius;
	UIColor *borderColor;
	UIColor *fillColor;				// super's backgroundColor seems to always draw and I couldn't figure out how to stop that. Use this instead
	
	//UIFont *font;
	//NSString *text;
}

@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic, retain) UIColor *fillColor;

//@property (nonatomic, retain) UIFont *font;
//@property (nonatomic, retain) NSString *text;

@end
