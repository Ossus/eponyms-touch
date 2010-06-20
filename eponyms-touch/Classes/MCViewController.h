//
//  MCViewController.h
//  medcalc
//
//  Created by Pascal Pfiffner on 06.02.10.
//	Copyright 2010 MedCalc. All rights reserved.
//	This sourcecode is released under the Apache License, Version 2.0
//	http://www.apache.org/licenses/LICENSE-2.0.html/
//  
//  A viewcontroller that can save its state automatically
//  

#import <UIKit/UIKit.h>

#define MCViewRestoreNoLaterThanDate @"restoreNoLaterThan"		// if set, restoreState will do nothing after the given NSDate


@interface MCViewController : UIViewController {
	MCViewController *myParentController;					// workaround for the @private parentViewController of UIViewController :P
	BOOL shouldBeDismissed;									// YES by default. If NO, modal views can't be dismissed
	NSString *autosaveName;
	NSDictionary *restoreOnLoad;
}

@property (nonatomic, assign) MCViewController *myParentController;
@property (nonatomic, assign) BOOL shouldBeDismissed;
@property (nonatomic, copy) NSString *autosaveName;

- (BOOL) isDisplayedModal;
- (void) dismissFromModal:(id)sender;

- (void) saveState;
- (void) restoreState;
- (BOOL) canRestoreState;
- (BOOL) willRestoreState;
- (NSDictionary *) currentState;							// override in subclasses, return nil if view has not been loaded
- (void) restoreStateFrom:(NSDictionary *)state;			// call this method to restore
- (void) setStateTo:(NSDictionary *)state;					// this internally gets called by "restoreStateFrom:"; override in subclasses


@end
