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
#define pPortraitContentMargin 20.0;
#define pLandscapeContentMargin 10.0;


@interface InfoViewController (Private)
- (void) adjustContentToOrientation;
- (void) loadEponymXMLFromDisk;
@end




@implementation InfoViewController

@synthesize delegate, needToReloadEponyms, firstTimeLaunch, newEponymsAvailable, myUpdater;
@synthesize lastEponymCheck, lastEponymUpdate, usingEponymsOf, readyToLoadNumEponyms, progressText, progressView, updateButton;
@synthesize infoPlistDict, projectWebsiteURL, eponymUpdateCheckURL, eponymXMLURL;

@dynamic iAmUpdating;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		iAmUpdating = NO;
		askingToAbortImport = NO;
		self.needToReloadEponyms = NO;
		self.newEponymsAvailable = NO;
		self.title = @"About Eponyms";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissMe:)] autorelease];
		
		// NSBundle Info.plist
		self.infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.projectWebsiteURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"projectWebsite"]];
		self.eponymUpdateCheckURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"eponymUpdateCheckURL"]];
		self.eponymXMLURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"eponymXMLURL"]];
	}
	return self;
}

- (void) dealloc
{
	[infoPlistDict release];				infoPlistDict = nil;
	[projectWebsiteURL release];			projectWebsiteURL = nil;
	[eponymUpdateCheckURL release];			eponymUpdateCheckURL = nil;
	[eponymXMLURL release];					eponymXMLURL = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark KVC
- (BOOL) iAmUpdating
{
	return iAmUpdating;
}
- (void) setIAmUpdating:(BOOL)updating
{
	iAmUpdating = updating;
	
	if(updating) {			// lock GUI (because we're not showing a modal sheet)
		updateButton.enabled = NO;
		projectWebsiteButton.enabled = NO;
		eponymsDotNetButton.enabled = NO;
		self.navigationItem.rightBarButtonItem.title = @"Abort";
	}
	else {					// release GUI
		updateButton.enabled = YES;
		projectWebsiteButton.enabled = YES;
		eponymsDotNetButton.enabled = YES;
		self.navigationItem.rightBarButtonItem.title = @"Done";
	}
}
#pragma mark -



#pragma mark GUI
- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate usingEponyms:(NSDate *)usingEponyms
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// last check
	if(lastCheck) {
		NSString *lastCheckString = ([lastCheck timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastCheck] : @"Never";
		[lastCheckLabel setText:[NSString stringWithFormat:@"Last Eponym Check: %@", lastCheckString]];
	}
	
	// last update
	if(lastUpdate) {
		NSString *lastUpdateString = ([lastUpdate timeIntervalSince1970] > 10.0) ? [dateFormatter stringFromDate:lastUpdate] : @"Never";
		[lastUpdateLabel setText:[NSString stringWithFormat:@"Last Eponym Update: %@", lastUpdateString]];
	}
	
	// using eponyms
	if(usingEponyms) {
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
	if(nil == color) {
		color = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];		// default button text color
	}
	[updateButton setTitleColor:color forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void) setStatusMessage:(NSString *)message
{
	if(message) {
		self.progressText.hidden = NO;
		self.progressText.text = message;
	}
	else {
		self.progressText.hidden = YES;
	}
}

- (void) setProgress:(CGFloat)progress
{
	if(progress >= 0.0) {
		self.progressView.hidden = NO;
		self.progressView.progress = progress;
	}
	else {
		self.progressView.hidden = YES;
	}
}


- (void) dismissMe:(id)sender
{
	// warning when closing during import
	if(iAmUpdating) {
		askingToAbortImport = YES;
		NSString *warning = @"Are you sure you want to abort the eponym import? This will discard any imported eponyms.";
		[self alertViewWithTitle:CANCEL_IMPORT_TITLE message:warning cancelTitle:@"Continue" otherTitle:@"Abort Import"];
	}
	
	// not importing
	else {
		[[self parentViewController] dismissModalViewControllerAnimated:YES];
		
		// New Eponyms - update
		if(needToReloadEponyms) {
			[delegate loadDatabaseAnimated:YES reload:YES];
		}
		
		if(myUpdater) {
			[myUpdater release];
		}
	}
}
#pragma mark -



#pragma mark View Controller Delegate
- (void) viewDidLoad
{
	// hide progress stuff
	progressText.hidden = YES;
	progressView.hidden = YES;
	updateButton.enabled = YES;
	[self setUpdateButtonTitle:@"Check for Eponym Updates"];
	
	// text
	[infoTextView setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
	infoTextView.text = [infoTextView.text stringByAppendingString:[projectWebsiteURL absoluteString]];
	
	// last update date/time
	[lastCheckLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
	[lastUpdateLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
	[usingEponymsLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
	
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSince1970:lastEponymCheck];
	NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastEponymUpdate];
	NSDate *usingEponymsDate = [NSDate dateWithTimeIntervalSince1970:usingEponymsOf];
	[self updateLabelsWithDateForLastCheck:lastCheckDate lastUpdate:lastUpdateDate usingEponyms:usingEponymsDate];
	
	// version
	[versionLabel setFont:[UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]]];
	
	NSString *version = [NSString stringWithFormat:@"Version %@  (%@)", [infoPlistDict objectForKey:@"CFBundleVersion"], [infoPlistDict objectForKey:@"SubversionRevision"]];
	[versionLabel setText:version];
}

- (void) viewDidAppear:(BOOL)animated
{
	if(firstTimeLaunch) {
		NSString *title = @"First Launch";
		NSString *message = @"Welcome to Eponyms!\nBefore using Eponyms, the database must be created.";
		
		[self alertViewWithTitle:title message:message cancelTitle:@"OK"];		// maybe allow postponing first import?
	}
	
	[self adjustContentToOrientation];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self adjustContentToOrientation];
}

- (void) adjustContentToOrientation
{
	UIInterfaceOrientation orientation = [self interfaceOrientation];
	CGFloat screenWidth = topContainer.superview.frame.size.width;
	CGRect topRect = topContainer.frame;
	CGRect bottomRect = bottomContainer.frame;
	
	// Portrait
	if((UIInterfaceOrientationPortrait == orientation) || (UIInterfaceOrientationPortraitUpsideDown == orientation)) {
		topRect.size.width = screenWidth - 2 * pPortraitContentMargin;
		topRect.origin.x = pPortraitContentMargin;
		bottomRect.size.width = screenWidth - 2 * pPortraitContentMargin;
		bottomRect.origin.x = pPortraitContentMargin;
	}
	
	// Landscape
	else {
		topRect.size.width = screenWidth / 2 - 2 * pLandscapeContentMargin;
		topRect.origin.x = pLandscapeContentMargin;
		bottomRect.size.width = screenWidth / 2 - 2 * pLandscapeContentMargin;
		bottomRect.origin.x = screenWidth / 2 + pLandscapeContentMargin;
	}
	
	topContainer.frame = topRect;
	bottomContainer.frame = bottomRect;
}

- (void) didReceiveMemoryWarning
{
	[self dismissMe:nil];
	[super didReceiveMemoryWarning];		// Releases the view if it doesn't have a superview !! (still needed after a dismiss??)
}
#pragma mark -



#pragma mark EponymUpdater
- (void) loadEponymXMLFromDisk
{
	self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	myUpdater.updateAction = 2;
	
	// Info.plist
	myUpdater.readyToLoadNumEponyms = [[infoPlistDict objectForKey:@"numberOfIncludedEponyms"] intValue];
	
	// read the XML into data
	NSString *eponymXMLPath = [NSBundle pathForResource:@"eponyms" ofType:@"xml" inDirectory:[[NSBundle mainBundle] bundlePath]];
	NSData *includedXMLData = [NSData dataWithContentsOfFile:eponymXMLPath];
	[myUpdater createEponymsWithData:includedXMLData];
}

- (IBAction) performUpdateAction:(id) sender
{
	NSUInteger updateAction = newEponymsAvailable ? 2 : 1;				// 1: check  2: download new
	self.myUpdater = [[[EponymUpdater alloc] initWithDelegate:self] autorelease];
	myUpdater.updateAction = updateAction;
	
	// We are going to update the eponyms - tell the updater how many eponyms to expect
	if(2 == updateAction) {
		myUpdater.readyToLoadNumEponyms = readyToLoadNumEponyms;
	}
	
	[myUpdater startDownloadingWithAction:updateAction];
}

- (void) abortUpdateAction
{
	if(myUpdater) {
		myUpdater.mustAbortImport = YES;
	}
	
	self.iAmUpdating = NO;
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
	if(askingToAbortImport) {
		if(buttonIndex == alertView.firstOtherButtonIndex) {
			[self abortUpdateAction];
			[self dismissMe:nil];
		}
	}
	
	// first import alert (can only be accepted ATM)
	else if(firstTimeLaunch) {
		[self loadEponymXMLFromDisk];
		firstTimeLaunch = NO;
	}
}
#pragma mark -



#pragma mark Online Access
- (void) openWebsite:(NSURL *)url fromButton:(id) button
{
	if(![[UIApplication sharedApplication] openURL:url]) {
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
