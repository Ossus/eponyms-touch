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


#import "eponyms_touchAppDelegate.h"
#import "InfoViewController.h"
#import "EponymUpdater.h"


#define CANCEL_IMPORT_TITLE @"Cancel import?"


@interface InfoViewController (Private)

- (void) switchToTab:(NSUInteger)tab;
- (void) lockGUI:(BOOL)lock;
- (void) newEponymsAreAvailable:(BOOL)available;
- (void) resetStatusElementsWithButtonTitle:(NSString *)buttonTitle;

@end




@implementation InfoViewController

@synthesize delegate;
@synthesize firstTimeLaunch;
@synthesize lastEponymCheck;
@synthesize lastEponymUpdate;
@synthesize infoPlistDict;
@synthesize projectWebsiteURL;
@synthesize parentView;
@synthesize infoView;
@synthesize updatesView;
@synthesize optionsView;
@synthesize tabSegments;
@synthesize versionLabel;
@synthesize usingEponymsLabel;
@synthesize projectWebsiteButton;
@synthesize eponymsDotNetButton;
@synthesize lastCheckLabel;
@synthesize lastUpdateLabel;
@synthesize progressText;
@synthesize progressView;
@synthesize updateButton;
@synthesize autocheckSwitch;
@synthesize allowRotateSwitch;
@synthesize allowLearnModeSwitch;


- (id) init
{
	NSString *thisNibName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"InfoView-iPad" : @"InfoView";
	return [self initWithNibName:thisNibName bundle:nil];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		askingToAbortImport = NO;
		
		// compose the navigation bar
		NSArray *possibleTabs = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			possibleTabs = [NSArray arrayWithObjects:@"About", @"Update", nil];
		}
		else {
			possibleTabs = [NSArray arrayWithObjects:@"About", @"Update", @"Options", nil];
		}
		
		self.tabSegments = [[UISegmentedControl alloc] initWithItems:possibleTabs];
		tabSegments.selectedSegmentIndex = 0;
		tabSegments.segmentedControlStyle = UISegmentedControlStyleBar;
		tabSegments.frame = CGRectMake(0.0, 0.0, 220.0, 30.0);
		tabSegments.autoresizingMask = UIViewAutoresizingNone;
		[tabSegments addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.titleView = tabSegments;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissMe:)] autorelease];
		
		// NSBundle Info.plist
		self.infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.projectWebsiteURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"projectWebsite"]];
	}
	return self;
}

- (void) dealloc
{
	self.infoPlistDict = nil;
	self.projectWebsiteURL = nil;
	self.tabSegments = nil;
	
	// IBOutlets
	self.parentView = nil;
	self.tabSegments = nil;
	
	self.infoView = nil;
	self.updatesView = nil;
	self.optionsView = nil;
	
	self.versionLabel = nil;
	self.usingEponymsLabel = nil;
	self.projectWebsiteButton = nil;
	self.eponymsDotNetButton = nil;
	
	self.lastCheckLabel = nil;
	self.lastUpdateLabel = nil;
	self.progressText = nil;
	self.progressView = nil;
	self.updateButton = nil;
	self.autocheckSwitch = nil;
	
	self.allowRotateSwitch = nil;
	self.allowLearnModeSwitch = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark View Controller Delegate
- (void) viewDidLoad
{
	tabSegments.tintColor = [delegate naviBarTintColor];
	
	// hide progress stuff
	[self setStatusMessage:nil];
	[self resetStatusElementsWithButtonTitle:nil];
	
	// last update date/time
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSince1970:lastEponymCheck];
	NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastEponymUpdate];
	NSDate *usingEponymsDate = [NSDate dateWithTimeIntervalSince1970:[delegate usingEponymsOf]];
	[self updateLabelsWithDateForLastCheck:lastCheckDate lastUpdate:lastUpdateDate usingEponyms:usingEponymsDate];
	
	// version
	NSString *version = [NSString stringWithFormat:@"Version %@  (%@)", [infoPlistDict objectForKey:@"CFBundleVersion"], [infoPlistDict objectForKey:@"SubversionRevision"]];
	[versionLabel setText:version];
}

- (void) viewWillAppear:(BOOL)animated
{
	BOOL mustSeeProgress = firstTimeLaunch || [delegate newEponymsAvailable];
	
	if (mustSeeProgress) {
		[self switchToTab:1];
	}
	else {
		[self switchToTab:tabSegments.selectedSegmentIndex];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	if (firstTimeLaunch) {
		NSString *title = @"First Launch";
		NSString *message = @"Welcome to Eponyms!\nBefore using Eponyms, the database must be created.";
		
		[self alertViewWithTitle:title message:message cancelTitle:@"OK"];		// maybe allow postponing first import?
	}
	
	// Adjust options
	eponyms_touchAppDelegate *appDelegate = (eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate];
	autocheckSwitch.on = [delegate shouldAutoCheck];
	allowRotateSwitch.on = appDelegate.allowAutoRotate;
	allowLearnModeSwitch.on = appDelegate.allowLearnMode;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
	
	// very difficult to get good results in the info view, so don't allow rotation
	return IS_PORTRAIT(toInterfaceOrientation);
}

- (void) dismissMe:(id)sender
{
	// warning when closing during import
	if ([delegate iAmUpdating]) {
		askingToAbortImport = YES;
		NSString *warning = @"Are you sure you want to abort the eponym import? This will discard any imported eponyms.";
		[self alertViewWithTitle:CANCEL_IMPORT_TITLE message:warning cancelTitle:@"Continue" otherTitle:@"Abort Import"];
	}
	
	// not importing
	else {
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
}
#pragma mark -



#pragma mark GUI
- (void) tabChanged:(id)sender
{
	UISegmentedControl *segment = sender;
	[self switchToTab:segment.selectedSegmentIndex];
}

- (void) switchToTab:(NSUInteger)tab
{
	tabSegments.selectedSegmentIndex = tab;
	
	// remove current view
	[[parentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	UIView *viewToAdd = nil;
	BOOL adjustFrame = YES;
	
	// Show the About page
	if (0 == tab) {
		viewToAdd = infoView;
		adjustFrame = NO;
	}
	
	// Show the update tab
	else if (1 == tab) {
		viewToAdd = updatesView;
		
		// adjust the elements
		if ([delegate didCheckForNewEponyms]) {
			[self newEponymsAreAvailable:[delegate newEponymsAvailable]];
		}
	}
	
	// Show the options
	else {
		viewToAdd = optionsView;
	}
	
	// add the view?
	if (nil != viewToAdd) {
		if (adjustFrame) {
			viewToAdd.frame = parentView.bounds;
		}
		
		[parentView addSubview:viewToAdd];
		parentView.contentSize = viewToAdd.frame.size;
		parentView.contentOffset = CGPointZero;
	}
}

- (void) newEponymsAreAvailable:(BOOL)available
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

- (void) resetStatusElementsWithButtonTitle:(NSString *)buttonTitle
{
	[self setUpdateButtonTitle:(buttonTitle ? buttonTitle : @"Check for Eponym Updates")];
	[self setUpdateButtonTitleColor:nil];
	[self setProgress:-1.0];
}

- (void) lockGUI:(BOOL)lock
{
	if (lock) {
		updateButton.enabled = NO;
		projectWebsiteButton.enabled = NO;
		eponymsDotNetButton.enabled = NO;
		autocheckSwitch.enabled = NO;
		self.navigationItem.rightBarButtonItem.title = @"Abort";
	}
	else {
		updateButton.enabled = YES;
		projectWebsiteButton.enabled = YES;
		eponymsDotNetButton.enabled = YES;
		autocheckSwitch.enabled = YES;
		self.navigationItem.rightBarButtonItem.title = @"Done";
	}
}

- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// last check
	if (lastCheck) {
		[lastCheckLabel setText:([lastCheck timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastCheck] : @"Never"];
	}
	
	// last update
	if (lastUpdate) {
		[lastUpdateLabel setText:([lastUpdate timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastUpdate] : @"Never"];
	}
	
	// using eponyms
	if (usingEponyms) {
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSString *usingEponymsString = ([usingEponyms timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:usingEponyms] : @"Unknown";
		[usingEponymsLabel setText:[NSString stringWithFormat:@"Eponyms Date: %@", usingEponymsString]];
	}
	
	[dateFormatter release];
}


- (void) setUpdateButtonTitle:(NSString *)title
{
	[updateButton setTitle:title forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
}

- (void) setUpdateButtonTitleColor:(UIColor *)color
{
	if (nil == color) {
		color = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];		// default button text color
	}
	[updateButton setTitleColor:color forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void) setStatusMessage:(NSString *)message
{
	if (message) {
		progressText.textColor = [UIColor blackColor];
		progressText.text = message;
	}
	else {
		progressText.textColor = [UIColor grayColor];
		progressText.text = @"Ready";
	}
}

- (void) setProgress:(CGFloat)progress
{
	if (progress >= 0.0) {
		progressView.hidden = NO;
		progressView.progress = progress;
	}
	else {
		progressView.hidden = YES;
	}
}

- (IBAction) switchToggled:(id)sender
{
	UISwitch *mySwitch = sender;
	eponyms_touchAppDelegate *appDelegate = (eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (autocheckSwitch == mySwitch) {
		[delegate setShouldAutoCheck:mySwitch.on];
	}
	else if (allowRotateSwitch == mySwitch) {
		appDelegate.allowAutoRotate = mySwitch.on;
	}
	else if (allowLearnModeSwitch == mySwitch) {
		appDelegate.allowLearnMode = mySwitch.on;
	}
}
#pragma mark -



#pragma mark Updater Delegate
- (void) updaterDidStartAction:(EponymUpdater *)updater
{
	[updater retain];
	[self lockGUI:YES];
	[self setStatusMessage:updater.statusMessage];
	[updater release];
}

- (void) updater:(EponymUpdater *)updater didEndActionSuccessful:(BOOL)success
{
	[updater retain];
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
	
	[updater release];
}

- (void) updater:(EponymUpdater *)updater progress:(CGFloat)progress
{
	[self setProgress:progress];
}
#pragma mark -



#pragma mark Alert View + Delegate
// alert with one button
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
	[alert show];
	[alert release];
}

// alert with 2 buttons
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
	[alert show];
	[alert release];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
	// abort import alert
	if (askingToAbortImport) {
		if (buttonIndex == alertView.firstOtherButtonIndex) {
			[delegate abortUpdateAction];
			[self dismissMe:nil];
		}
		askingToAbortImport = NO;
	}
	
	// first import alert (can only be accepted at the moment)
	else if (firstTimeLaunch) {
		[(eponyms_touchAppDelegate *)delegate loadEponymXMLFromDisk];
	}
}
#pragma mark -



#pragma mark Online Access
- (IBAction) performUpdateAction:(id)sender
{
	[delegate checkForUpdates:sender];
}

- (void) openWebsite:(NSURL *)url fromButton:(id) button
{
	if (![[UIApplication sharedApplication] openURL:url]) {
		[button setText:@"Failed"];
	}
}

- (IBAction) openProjectWebsite:(id) sender
{
	[self openWebsite:projectWebsiteURL fromButton:sender];
}

- (IBAction) openEponymsDotNet:(id) sender
{
	[self openWebsite:[NSURL URLWithString:@"http://www.eponyms.net/"] fromButton:sender];
}




@end
