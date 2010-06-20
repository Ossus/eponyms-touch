//
//  MCViewController.m
//  medcalc
//
//  Created by Pascal Pfiffner on 06.02.10.
//	Copyright 2010 MedCalc. All rights reserved.
//	This sourcecode is released under the Apache License, Version 2.0
//	http://www.apache.org/licenses/LICENSE-2.0.html/
//  
//  A viewcontroller that can save its state automatically
//  

#import "MCViewController.h"

#define kMCVCStateSaveMask @"MCVC_lastState_%@"


@interface MCViewController ()

@property (nonatomic, retain) NSDictionary *restoreOnLoad;

- (void) willQuit;
- (NSString *) stateSaveName;

@end



@implementation MCViewController

@synthesize myParentController;
@synthesize shouldBeDismissed;
@dynamic autosaveName;
@synthesize restoreOnLoad;


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.autosaveName = nil;
	self.restoreOnLoad = nil;
	
	[super dealloc];
}

- (id) init
{
	return [self initWithNibName:nil bundle:nil];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		shouldBeDismissed = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willQuit)
													 name:UIApplicationWillTerminateNotification
												   object:nil];
	}
	return self;
}
#pragma mark -



#pragma mark KVC
- (NSString *) autosaveName
{
	return autosaveName;
}
- (void) setAutosaveName:(NSString *)newName
{
	if (newName != autosaveName) {
		[autosaveName release];
		autosaveName = [newName copy];
		
		if (nil != autosaveName) {
			[self restoreState];
		}
	}
}
#pragma mark -



#pragma mark View Tasks
- (void) viewDidLoad
{
	[super viewDidLoad];
	
	// calling this here is too early for some states!
	/*
	if (nil != restoreOnLoad) {
		[self restoreStateFrom:restoreOnLoad];
		self.restoreOnLoad = nil;
	}	//	*/
}

- (BOOL) isDisplayedModal
{
	UIViewController *child = self;
	UIViewController *parent = nil;
	while (parent = child.parentViewController) {
		if (child == parent.modalViewController) {
			return YES;
		}
		child = parent;
	}
	return NO;
}

- (void) dismissFromModal:(id)sender
{
	UIViewController *child = self;
	UIViewController *parent = nil;
	while (parent = child.parentViewController) {
		if (child == parent.modalViewController) {
			[parent dismissModalViewControllerAnimated:(nil != sender)];
			return;
		}
		child = parent;
	}
	
	if (self == myParentController.modalViewController) {
		[myParentController dismissModalViewControllerAnimated:(nil != sender)];
	}
}
#pragma mark -



#pragma mark State saving and restoring
- (void) willQuit
{
	[self saveState];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) stateSaveName
{
	return [NSString stringWithFormat:kMCVCStateSaveMask, autosaveName];
}

- (void) saveState
{
	if (nil != autosaveName) {
		NSDictionary *state = [self currentState];
		
		if (nil != state) {
			[[NSUserDefaults standardUserDefaults] setObject:state forKey:[self stateSaveName]];
		}
	}
}

- (void) restoreState
{
	if (restoreOnLoad) {
		[self restoreStateFrom:restoreOnLoad];
	}
	else if (autosaveName) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *saveName = [self stateSaveName];
		
		NSDictionary *lastState = [defaults objectForKey:saveName];
		if ([lastState isKindOfClass:[NSDictionary class]]) {
			BOOL allow = YES;
			NSDate *latestDate = [lastState objectForKey:MCViewRestoreNoLaterThanDate];
			if ([latestDate isKindOfClass:[NSDate class]]) {
				allow = (latestDate == [latestDate laterDate:[NSDate date]]);
			}
			if (allow) {
				[self restoreStateFrom:lastState];
			}
		}
		[defaults removeObjectForKey:saveName];
	}
}

- (BOOL) canRestoreState
{
	if (restoreOnLoad) {
		return YES;
	}
	if (autosaveName) {
		return (nil != [[NSUserDefaults standardUserDefaults] objectForKey:[self stateSaveName]]);
	}
	return NO;
}

- (BOOL) willRestoreState
{
	return (nil != restoreOnLoad);
}

- (NSDictionary *) currentState
{
	if ([self isViewLoaded]) {
		// will hopefully be overridden by subclasses
	}
	return nil;
}

- (void) restoreStateFrom:(NSDictionary *)state
{
	if ([self isViewLoaded]) {
		[self setStateTo:state];
	}
	else {
		self.restoreOnLoad = state;
	}
}

- (void) setStateTo:(NSDictionary *)state
{
	// This method should only be called when the view is loaded
	// Call "restoreStateFrom:" which will ensure that the view is loaded and subsequently call this method
}


@end
