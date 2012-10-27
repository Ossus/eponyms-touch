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

@property (nonatomic, strong) NSDictionary *restoreOnLoad;

- (void) willQuit;
- (NSString *) stateSaveName;

@end



@implementation MCViewController

@synthesize myParentController;
@synthesize shouldBeDismissed;
@synthesize restoreOnLoad;


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id) init
{
	return [self initWithNibName:nil bundle:nil];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		shouldBeDismissed = YES;
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(willQuit) name:UIApplicationWillTerminateNotification object:nil];
		if (&UIApplicationDidEnterBackgroundNotification != NULL) {
			[center addObserver:self selector:@selector(willQuit) name:UIApplicationDidEnterBackgroundNotification object:nil];
		}
	}
	return self;
}



#pragma mark - KVC
- (void)setAutosaveName:(NSString *)newName
{
	if (newName != _autosaveName) {
		_autosaveName = [newName copy];
		
		if (nil != _autosaveName) {
			[self restoreState];
		}
	}
}



#pragma mark - View Tasks
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (nil != restoreOnLoad) {
		[self performSelector:@selector(restoreStateFrom:) withObject:restoreOnLoad afterDelay:0.0];
		self.restoreOnLoad = nil;
	}
}


- (BOOL) isDisplayedModal
{
	UIViewController *child = self;
	UIViewController *parent = nil;
	while ((parent = child.parentViewController)) {
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
	while ((parent = child.parentViewController)) {
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
	[[NSUserDefaults standardUserDefaults] synchronize];		// this should be done by the app delegate, but often it's too late
}

- (NSString *) stateSaveName
{
	return [NSString stringWithFormat:kMCVCStateSaveMask, _autosaveName];
}

- (void) saveState
{
	if (nil != _autosaveName) {
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
	else if (_autosaveName) {
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
		else if (lastState) {
			[defaults removeObjectForKey:saveName];
		}
	}
}

- (BOOL) canRestoreState
{
	if (restoreOnLoad) {
		return YES;
	}
	if (_autosaveName) {
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
		
		// clean up
		self.restoreOnLoad = nil;
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:[self stateSaveName]];
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
