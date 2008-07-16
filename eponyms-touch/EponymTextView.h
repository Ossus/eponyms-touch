//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  UITextView subclass that draws rounded corners for eponyms-touch
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
