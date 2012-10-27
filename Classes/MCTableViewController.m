//
//  MCTableViewController.m
//  medcalc
//
//  Created by Pascal Pfiffner on 09.01.10.
//	Copyright 2010 MedCalc. All rights reserved.
//	This sourcecode is released under the Apache License, Version 2.0
//	http://www.apache.org/licenses/LICENSE-2.0.html/
//  
//  A tableviewcontroller that can save its state automatically. Uses TouchTableView instead of UITableView.
//  

#import "MCTableViewController.h"
#import "TouchTableView.h"
#import "AppDelegate.h"

#define kMCTVCStateSaveMask @"MCTVC_lastState_%@"


@interface MCTableViewController ()

- (NSString *) stateSaveName;
- (void) registerForKeyboardNotifications;
- (void) forgetAboutKeyboardNotifications;
- (void) keyboardDidShow:(NSNotification*)aNotification;
- (void) keyboardWillHide:(NSNotification*)aNotification;

@end



@implementation MCTableViewController

@synthesize tableStyle;


- (void)viewDidUnload
{
	self.tableView = nil;
	
	[super viewDidUnload];
}


- (id)init
{
	return [self initWithStyle:UITableViewStylePlain];
}

- (id)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
		tableStyle = style;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nil bundle:nil])) {		// check whether this can be improved when loading from XIBs
		tableStyle = UITableViewStylePlain;
	}
	return self;
}



#pragma mark - KVC
- (void)setTableView:(TouchTableView *)newTableView
{
	if (newTableView != _tableView) {
		_tableView = newTableView;
		
		if (nil != _tableView && nil != _noDataHint) {
			_tableView.noDataHint = _noDataHint;
		}
	}
}



#pragma mark - View Tasks
- (void)loadView
{
	// create the table
	CGRect availRect = [[UIScreen mainScreen] applicationFrame];
	if (nil != self.tabBarController) {
		CGRect tabBarRect = [self.tabBarController tabBar].bounds;
		availRect.size.height -= tabBarRect.size.height;
	}
	
	self.tableView = [[TouchTableView alloc] initWithFrame:availRect style:tableStyle];
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_tableView.autoresizesSubviews = YES;
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	self.view = _tableView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (shouldShowDataHintAfterLoading) {
		[self showNoDataHintAnimated:NO];
		shouldShowDataHintAfterLoading = NO;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self registerForKeyboardNotifications];
	
	NSIndexPath *selectedRow = [_tableView indexPathForSelectedRow];
	if (selectedRow) {
		[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedRow] withRowAnimation:UITableViewRowAnimationNone];
		[_tableView deselectRowAtIndexPath:selectedRow animated:animated];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self forgetAboutKeyboardNotifications];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[_tableView setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
}



#pragma mark - No Data Hint
- (void)setNoDataHint:(NSString *)newHint
{
	if (newHint != _noDataHint) {
		_noDataHint = [newHint copy];
		
		if (_tableView) {
			_tableView.noDataHint = _noDataHint;
		}
	}
}

- (void)showNoDataHintAnimated:(BOOL)animated
{
	if ([self isViewLoaded]) {
		[_tableView showNoDataLabelAnimated:animated];
	}
	else {
		shouldShowDataHintAfterLoading = YES;
	}
}

- (void)hideNoDataHintAnimated:(BOOL)animated
{
	[_tableView hideNoDataLabelAnimated:animated];
}



#pragma mark - Data Source and Delegate
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return 0;
}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (BOOL)tableView:(TouchTableView *)aTableView rowIsVisible:(NSIndexPath *)indexPath
{
	CGRect visibleRect = aTableView.bounds;
	visibleRect.origin.y = aTableView.contentOffset.y;
	CGRect rowRect = [aTableView rectForRowAtIndexPath:indexPath];
	
	return CGRectIntersectsRect(rowRect, visibleRect);
}



#pragma mark - State saving and restoring
- (NSString *)stateSaveName
{
	return [NSString stringWithFormat:kMCTVCStateSaveMask, self.autosaveName];
}

- (NSDictionary *)currentState
{
	if ([self isViewLoaded]) {
		
		// get scroll position
		NSNumber *scrollPos = [NSNumber numberWithFloat:self.tableView.contentOffset.y];
		NSDictionary *state = [NSDictionary dictionaryWithObject:scrollPos forKey:@"scrollPosition"];
		return state;
	}
	return nil;
}

- (void)setStateTo:(NSDictionary *)state
{
	if ([state isKindOfClass:[NSDictionary class]]) {
		NSNumber *scrollPos = [state objectForKey:@"scrollPosition"];
		if (nil != scrollPos) {
			CGFloat scr = [scrollPos floatValue];
			if (scr > [self.tableView contentSize].height) {
				scr = [self.tableView contentSize].height - [self.tableView frame].size.height;
			}
			self.tableView.contentOffset = CGPointMake(0.f, scr);
		}
	}
}



#pragma mark - UIKeyboardNotifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
}

- (void)forgetAboutKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardDidShow:(NSNotification*)aNotification
{
	NSDictionary *info = [aNotification userInfo];
	
	// get frame information
	CGRect endRectOriginal = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect endRect = [self.view convertRect:endRectOriginal fromView:self.view.window];
	
	// resize the view
	CGRect viewFrame = _tableView.frame;
	CGRect intersection = CGRectIntersection(viewFrame, endRect);
	CGFloat endHeight = fmaxf(0.f, intersection.size.height);			// adding the origin compensates for a search input view that will move to the top
	//DLog(@"%@ -> %@: %.0f", NSStringFromCGRect(viewFrame), NSStringFromCGRect(intersection), endHeight);
	
	_tableView.contentInset = UIEdgeInsetsMake(0.f, 0.f, endHeight, 0.f);
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
	_tableView.contentInset = UIEdgeInsetsZero;
}



@end
