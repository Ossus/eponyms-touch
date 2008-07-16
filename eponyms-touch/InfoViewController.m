//
//  InfoViewController.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 01.07.08.
//  Copyright 2008 home sweet home. All rights reserved.
//

#import "eponyms_touchAppDelegate.h"
#import "InfoViewController.h"
#import "EponymUpdater.h"


#define CANCEL_IMPORT_TITLE @"Cancel import?"


@interface InfoViewController (Private)

- (void) loadEponymXMLFromDisk;

@end




@implementation InfoViewController

@synthesize delegate, database, needToReloadEponyms, firstTimeLaunch, newEponymsAvailable, myUpdater;
@synthesize lastEponymCheck, lastEponymUpdate, usingEponymsOf, readyToLoadNumEponyms, progressText, progressView, updateButton;
@synthesize infoPlistDict, projectWebsiteURL, eponymUpdateCheckURL, eponymXMLURL;

@dynamic iAmUpdating;


- (id) initWithNibName:(NSString *) nibNameOrNil bundle:(NSBundle *) nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		iAmUpdating = NO;
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
	[infoPlistDict release];
	[projectWebsiteURL release];
	[eponymUpdateCheckURL release];
	[eponymXMLURL release];
	
	[super dealloc];
}
#pragma mark -



#pragma mark KVC
- (BOOL) iAmUpdating
{
	return iAmUpdating;
}
- (void) setIAmUpdating:(BOOL) updating
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
- (void) updateLabelsWithDateForLastCheck:(NSDate *) lastCheck lastUpdate:(NSDate *) lastUpdate usingEponyms:(NSDate *) usingEponyms
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


- (void) setUpdateButtonTitle:(NSString *) title
{
	[updateButton setTitle:title forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void) setUpdateButtonTitleColor:(UIColor *) color
{
	if(nil == color) {
		color = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];		// default button text color
	}
	[updateButton setTitleColor:color forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected & UIControlStateDisabled)];
}

- (void) setStatusMessage:(NSString *) message
{
	if(message) {
		self.progressText.hidden = NO;
		self.progressText.text = message;
	}
	else {
		self.progressText.hidden = YES;
	}
}

- (void) setProgress:(CGFloat) progress
{
	if(progress >= 0.0) {
		self.progressView.hidden = NO;
		self.progressView.progress = progress;
	}
	else {
		self.progressView.hidden = YES;
	}
}


- (void) dismissMe:(id) sender
{
	// warning when closing during import
	if(iAmUpdating) {
		UIAlertView *importingAlert = [[[UIAlertView alloc] initWithTitle:CANCEL_IMPORT_TITLE message:@"Are you sure you want to abort the eponym import? This will discard any imported eponyms." delegate:self cancelButtonTitle:@"Keep importing" otherButtonTitles:@"Abort import"] autorelease];
		[importingAlert show];
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
	[versionLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
	
	NSString *version = [NSString stringWithFormat:@"Version %@", [infoPlistDict objectForKey:@"CFBundleVersion"]];
	[versionLabel setText:version];
}

- (void) viewDidAppear:(BOOL) animated
{
	if(firstTimeLaunch) {
		NSString *title = @"First Launch";
		NSString *message = @"Welcome to Eponyms!\nBefore using Eponyms, the database must be created.";
		UIAlertView *info = [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		info.delegate = self;
		[info show];
		firstTimeLaunch = NO;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) didReceiveMemoryWarning
{
	[self dismissMe:nil];
	[super didReceiveMemoryWarning];		// Releases the view if it doesn't have a superview !! (still needed after a dismiss??)
}
#pragma mark -



#pragma mark First Launch + Alert View Delegate
- (void) alertView:(UIAlertView *) alertView willDismissWithButtonIndex:(NSInteger) buttonIndex
{
	// abort import alert
	if([[alertView title] isEqualToString:CANCEL_IMPORT_TITLE]) {			// !! could be dangerous
		NSLog(@"Dismissed import alert with buttonIndex: %i", buttonIndex);
		
		// abort import
		if(NO) {
			
		}
		else {
			// keep importing
		}
	}
	
	// first import alert
	else {
		[self loadEponymXMLFromDisk];
	}
}

- (void) loadEponymXMLFromDisk
{
	self.myUpdater = [[[EponymUpdater alloc] init] autorelease];
	myUpdater.delegate = self;
	myUpdater.updateAction = 2;
	
	// Info.plist
	myUpdater.readyToLoadNumEponyms = [[infoPlistDict objectForKey:@"numberOfIncludedEponyms"] intValue];
	
	// read the XML into data
	NSString *eponymXMLPath = [NSBundle pathForResource:@"eponyms" ofType:@"xml" inDirectory:[[NSBundle mainBundle] bundlePath]];
	NSData *includedXMLData = [NSData dataWithContentsOfFile:eponymXMLPath];
	[myUpdater createEponymsWithData:includedXMLData];
}
#pragma mark -



#pragma mark Online Access
- (IBAction) performUpdateAction:(id) sender
{
	NSUInteger updateAction = newEponymsAvailable ? 2 : 1;				// 1: check  2: download new
	self.myUpdater = [[[EponymUpdater alloc] init] autorelease];
	myUpdater.delegate = self;
	myUpdater.updateAction = updateAction;
	
	// We are going to update the eponyms - tell the updater how many eponyms to expect
	if(2 == updateAction) {
		myUpdater.readyToLoadNumEponyms = readyToLoadNumEponyms;
	}
	
	[myUpdater startDownloadingWithAction:updateAction];
}

- (void) openWebsite:(NSURL *) url fromButton:(id) button
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
