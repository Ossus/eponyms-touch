//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the info screen for eponyms-touch
//  


#import "AppDelegate.h"
#import "InfoViewController.h"
#import "EponymUpdater.h"


#define CANCEL_IMPORT_TITLE @"Cancel import?"


@interface InfoViewController (Private)

- (void)switchToTab:(NSUInteger)tab;
- (void)lockGUI:(BOOL)lock;
- (void)newEponymsAreAvailable:(BOOL)available;
- (void)resetStatusElementsWithButtonTitle:(NSString *)buttonTitle;

@end




@implementation InfoViewController


- (id)init
{
	NSString *thisNibName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"InfoView-iPad" : @"InfoView";
	return [self initWithNibName:thisNibName bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		askingToAbortImport = NO;
		
		// compose the navigation bar
		NSArray *possibleTabs = @[@"About", @"Update"];
		self.tabSegments = [[UISegmentedControl alloc] initWithItems:possibleTabs];
		_tabSegments.selectedSegmentIndex = 0;
		_tabSegments.segmentedControlStyle = UISegmentedControlStyleBar;
		_tabSegments.frame = CGRectMake(0.0, 0.0, 220.0, 30.0);
		_tabSegments.autoresizingMask = UIViewAutoresizingNone;
		[_tabSegments addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.titleView = _tabSegments;
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissMe:)];
		
		// NSBundle Info.plist
		self.infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.projectWebsiteURL = [NSURL URLWithString:[_infoPlistDict objectForKey:@"projectWebsite"]];
	}
	return self;
}



#pragma mark - View Controller Delegate
- (void)viewDidLoad
{
	// update colors
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-horizontal.png"]];
	_tabSegments.tintColor = [_delegate naviBarTintColor];
	
	// hide progress stuff
	[self setStatusMessage:nil];
	[self resetStatusElementsWithButtonTitle:nil];
	
	// last update date/time
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSince1970:_lastEponymCheck];
	NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:_lastEponymUpdate];
	NSDate *usingEponymsDate = [NSDate dateWithTimeIntervalSince1970:[_delegate usingEponymsOf]];
	[self updateLabelsWithDateForLastCheck:lastCheckDate lastUpdate:lastUpdateDate usingEponyms:usingEponymsDate];
	
	// version
	NSString *version = [NSString stringWithFormat:@"Version %@", [_infoPlistDict objectForKey:@"CFBundleVersion"]];
	[_versionLabel setText:version];
}

- (void)viewWillAppear:(BOOL)animated
{
	BOOL mustSeeProgress = _firstTimeLaunch || [_delegate newEponymsAvailable];
	
	if (mustSeeProgress) {
		[self switchToTab:1];
	}
	else {
		[self switchToTab:_tabSegments.selectedSegmentIndex];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	if (_firstTimeLaunch) {
		NSString *title = @"First Launch";
		NSString *message = @"Welcome to Eponyms!\nBefore using Eponyms, the database must be created.";
		
		[self alertViewWithTitle:title message:message cancelTitle:@"OK"];		// maybe allow postponing first import?
	}
	
	// Adjust autocheck option
	_autocheckSwitch.on = [_delegate shouldAutoCheck];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
	
	// very difficult to get good results in the info view, so don't allow rotation
	return IS_PORTRAIT(toInterfaceOrientation);
}

/**
 *  iOS 6 and later
 */
- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}


- (void)dismissMe:(id)sender
{
	// warning when closing during import
	if ([_delegate iAmUpdating]) {
		askingToAbortImport = YES;
		NSString *warning = @"Are you sure you want to abort the eponym import? This will discard any imported eponyms.";
		[self alertViewWithTitle:CANCEL_IMPORT_TITLE message:warning cancelTitle:@"Continue" otherTitle:@"Abort Import"];
	}
	
	// not importing
	else {
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
}



#pragma mark - GUI
- (void)tabChanged:(id)sender
{
	UISegmentedControl *segment = sender;
	[self switchToTab:segment.selectedSegmentIndex];
}

- (void)switchToTab:(NSUInteger)tab
{
	_tabSegments.selectedSegmentIndex = tab;
	
	// remove current view
	[[_parentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	UIView *viewToAdd = nil;
	BOOL adjustFrame = YES;
	
	// Show the update tab
	if (1 == tab) {
		viewToAdd = _updatesView;
		
		// adjust the elements
		if ([_delegate didCheckForNewEponyms]) {
			[self newEponymsAreAvailable:[_delegate newEponymsAvailable]];
		}
	}
	
	// Show the About page
	else {
		viewToAdd = _infoView;
		adjustFrame = NO;
	}
	
	// add the view?
	if (nil != viewToAdd) {
		if (adjustFrame) {
			viewToAdd.frame = _parentView.bounds;
		}
		
		[_parentView addSubview:viewToAdd];
		_parentView.contentSize = viewToAdd.frame.size;
		_parentView.contentOffset = CGPointZero;
	}
}

- (void)newEponymsAreAvailable:(BOOL)available
{
	NSString *statusMessage = nil;
	if (available) {
		statusMessage = @"New eponyms are available!";
		[self setUpdateButtonTitle:@"Download New Eponyms"];
		[self setUpdateButtonTitleColor:[UIColor redColor]];
		[self setProgress:-1.0];
	}
	else {
		statusMessage = @"You are up to date";
		[self resetStatusElementsWithButtonTitle:nil];
	}
	
	[self setStatusMessage:statusMessage];
}

- (void)resetStatusElementsWithButtonTitle:(NSString *)buttonTitle
{
	[self setUpdateButtonTitle:(buttonTitle ? buttonTitle : @"Check for Eponym Updates")];
	[self setUpdateButtonTitleColor:nil];
	[self setProgress:-1.0];
}

- (void)lockGUI:(BOOL)lock
{
	if (lock) {
		_updateButton.enabled = NO;
		_projectWebsiteButton.enabled = NO;
		_eponymsDotNetButton.enabled = NO;
		_autocheckSwitch.enabled = NO;
		self.navigationItem.rightBarButtonItem.title = @"Abort";
	}
	else {
		_updateButton.enabled = YES;
		_projectWebsiteButton.enabled = YES;
		_eponymsDotNetButton.enabled = YES;
		_autocheckSwitch.enabled = YES;
		self.navigationItem.rightBarButtonItem.title = @"Done";
	}
}

- (void)updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// last check
	if (lastCheck) {
		[_lastCheckLabel setText:([lastCheck timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastCheck] : @"Never"];
	}
	
	// last update
	if (lastUpdate) {
		[_lastUpdateLabel setText:([lastUpdate timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastUpdate] : @"Never"];
	}
	
	// using eponyms
	if (usingEponyms) {
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSString *usingEponymsString = ([usingEponyms timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:usingEponyms] : @"Unknown";
		[_usingEponymsLabel setText:[NSString stringWithFormat:@"Eponyms Date: %@", usingEponymsString]];
	}
	
}


- (void)setUpdateButtonTitle:(NSString *)title
{
	[_updateButton setTitle:title forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
}

- (void)setUpdateButtonTitleColor:(UIColor *)color
{
	if (nil == color) {
		color = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];		// default button text color
	}
	[_updateButton setTitleColor:color forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void)setStatusMessage:(NSString *)message
{
	if (message) {
		_progressText.textColor = [UIColor blackColor];
		_progressText.text = message;
	}
	else {
		_progressText.textColor = [UIColor grayColor];
		_progressText.text = @"Ready";
	}
}

- (void)setProgress:(CGFloat)progress
{
	if (progress >= 0.0) {
		_progressView.hidden = NO;
		_progressView.progress = progress;
	}
	else {
		_progressView.hidden = YES;
	}
}

- (IBAction)switchToggled:(id)sender
{
	UISwitch *mySwitch = sender;
	if (_autocheckSwitch == mySwitch) {
		[_delegate setShouldAutoCheck:mySwitch.on];
	}
}



#pragma mark - Updater Delegate
- (void)updaterDidStartAction:(EponymUpdater *)updater
{
	[self lockGUI:YES];
	[self setStatusMessage:updater.statusMessage];
}

- (void)updater:(EponymUpdater *)updater didEndActionSuccessful:(BOOL)success
{
	[self lockGUI:NO];
	
	if (success) {
		
		// did check for updates
		if (1 == updater.updateAction) {
			[self newEponymsAreAvailable:updater.newEponymsAvailable];
			[self updateLabelsWithDateForLastCheck:[NSDate date] lastUpdate:nil usingEponyms:nil];
		}
		
		// did update eponyms
		else {
			NSString *statusMessage;
			
			if (updater.numEponymsParsed > 0) {
				statusMessage = [NSString stringWithFormat:@"Created %u eponyms", updater.numEponymsParsed];
				[self updateLabelsWithDateForLastCheck:nil lastUpdate:[NSDate date] usingEponyms:updater.eponymCreationDate];
			}
			else {
				statusMessage = @"No eponyms were created";
			}
			
			[self setStatusMessage:statusMessage];
			[self resetStatusElementsWithButtonTitle:nil];
			_delegate.newEponymsAvailable = NO;
		}
	}
	
	// an error occurred
	else {
		[self resetStatusElementsWithButtonTitle:@"Try Again"];		
		
		if (updater.downloadFailed && updater.statusMessage) {
			[self alertViewWithTitle:@"Download Failed" message:updater.statusMessage cancelTitle:@"OK"];
		}
		
		[self setStatusMessage:updater.statusMessage];
	}
	
}

- (void)updater:(EponymUpdater *)updater progress:(CGFloat)progress
{
	[self setProgress:progress];
}



#pragma mark - Alert View + Delegate
// alert with one button
- (void)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
	[alert show];
}

// alert with 2 buttons
- (void)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
	// abort import alert
	if (askingToAbortImport) {
		if (buttonIndex == alertView.firstOtherButtonIndex) {
			[_delegate abortUpdateAction];
			[self dismissMe:nil];
		}
		askingToAbortImport = NO;
	}
	
	// first import alert (can only be accepted at the moment)
	else if (_firstTimeLaunch) {
		[(AppDelegate *)_delegate loadEponymXMLFromDisk];
	}
}



#pragma mark - Online Access
- (IBAction)performUpdateAction:(id)sender
{
	[_delegate checkForUpdates:sender];
}

- (void)openWebsite:(NSURL *)url fromButton:(id) button
{
	if (![[UIApplication sharedApplication] openURL:url]) {
		[button setText:@"Failed"];
	}
}

- (IBAction)openProjectWebsite:(id) sender
{
	[self openWebsite:_projectWebsiteURL fromButton:sender];
}

- (IBAction)openEponymsDotNet:(id) sender
{
	[self openWebsite:[NSURL URLWithString:@"http://www.eponyms.net/"] fromButton:sender];
}


@end
