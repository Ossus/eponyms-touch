//
//  EponymViewController.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the eponym view for eponyms-touch
//  


#import "eponyms_touchAppDelegate.h"
#import "EponymViewController.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "MCTextView.h"
#import "GADAdSenseParameters.h"


#define pSideMargin 10.0
#define pLabelSideMargin 5.0
#define pHeightTitle 32.0
#define pDistanceTextFromTitle 8.0
#define pDistanceCatLabelFromText 8.0
#define pDistanceDateLabelsFromCat 8.0
#define pTotalSizeBottomMargin 10.0
#define kGoogleAdViewTopMargin 8.0

#define kGoogleAdSenseClientID @"ca-mb-app-pub-1234567890123456"


@interface EponymViewController ()

@property (nonatomic, readwrite, retain) GADAdViewController *adController;
- (void) adjustDisplayToContent;

- (BOOL) adViewExists;
- (void) addGoogleAdsToView:(UIView *)toView inRect:(CGRect)inRect;
- (void) loadGoogleAdsWithEponym:(Eponym *)eponym;

@end



@implementation EponymViewController

@synthesize delegate, eponymToBeShown;
@dynamic rightBarButtonStarredItem, rightBarButtonNotStarredItem;
@dynamic eponymTitleLabel;
@dynamic eponymTextView;
@dynamic eponymCategoriesLabel;
@dynamic dateCreatedLabel;
@dynamic dateUpdatedLabel;
@synthesize adController;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.title = @"Eponym";
	}
	return self;
}

- (void) dealloc
{
	self.eponymToBeShown = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	
	self.view = nil;
	self.adController = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark KVC
- (UIBarButtonItem *) rightBarButtonStarredItem
{
	if (nil == rightBarButtonStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[delegate starImageEponymActive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonStarredItem = [[[UIBarButtonItem alloc] initWithCustomView:myButton] autorelease];
	}
	return rightBarButtonStarredItem;
}
- (void) setRightBarButtonStarredItem:(UIBarButtonItem *)newBarButtonItem
{
	if (newBarButtonItem != rightBarButtonStarredItem) {
		[rightBarButtonStarredItem release];
		rightBarButtonStarredItem = [newBarButtonItem retain];
	}
}

- (UIBarButtonItem *) rightBarButtonNotStarredItem
{
	if (nil == rightBarButtonNotStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[delegate starImageEponymInactive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonNotStarredItem = [[[UIBarButtonItem alloc] initWithCustomView:myButton] autorelease];
	}
	return rightBarButtonNotStarredItem;
}
- (void) setRightBarButtonNotStarredItem:(UIBarButtonItem *)newBarButtonItem
{
	if (newBarButtonItem != rightBarButtonNotStarredItem) {
		[rightBarButtonNotStarredItem release];
		rightBarButtonNotStarredItem = [newBarButtonItem retain];
	}
}

- (UILabel *) eponymTitleLabel
{
	if (nil == eponymTitleLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
		CGRect titleRect = CGRectMake(pSideMargin, pSideMargin, fullWidth, pHeightTitle);
		
		self.eponymTitleLabel = [[[UILabel alloc] initWithFrame:titleRect] autorelease];
		eponymTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymTitleLabel.userInteractionEnabled = NO;
		eponymTitleLabel.font = [UIFont boldSystemFontOfSize:24.0];
		eponymTitleLabel.numberOfLines = 1;
		eponymTitleLabel.adjustsFontSizeToFitWidth = YES;
		eponymTitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		eponymTitleLabel.backgroundColor = [UIColor clearColor];
		eponymTitleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
		eponymTitleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return eponymTitleLabel;
}
- (void) setEponymTitleLabel:(UILabel *)newTitle
{
	if (newTitle != eponymTitleLabel) {
		[eponymTitleLabel release];
		eponymTitleLabel = [newTitle retain];
	}
}

- (MCTextView *) eponymTextView
{
	if (nil == eponymTextView) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
		CGRect textRect = CGRectMake(0.0, 0.0, fullWidth, 40.0);
		
		self.eponymTextView = [[[MCTextView alloc] initWithFrame:textRect] autorelease];
		eponymTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymTextView.userInteractionEnabled = NO;
		eponymTextView.editable = NO;
		eponymTextView.font = [UIFont systemFontOfSize:17.0];
		eponymTextView.borderColor = [UIColor colorWithWhite:0.6 alpha:1.0];
	}
	return eponymTextView;
}
- (void) setEponymTextView:(MCTextView *)newTextView
{
	if (newTextView != eponymTextView) {
		[eponymTextView release];
		eponymTextView = [newTextView retain];
	}
}

- (UILabel *) eponymCategoriesLabel
{
	if (nil == eponymCategoriesLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
		CGFloat labelWidth = fullWidth - 2 * pLabelSideMargin;
		CGRect catRect = CGRectMake(pLabelSideMargin, pDistanceCatLabelFromText, labelWidth, 19.0);
		
		self.eponymCategoriesLabel = [[[UILabel alloc] initWithFrame:catRect] autorelease];
		eponymCategoriesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymCategoriesLabel.font = [UIFont systemFontOfSize:17.0];
		eponymCategoriesLabel.backgroundColor = [UIColor clearColor];
		eponymCategoriesLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
		eponymCategoriesLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return eponymCategoriesLabel;
}
- (void) setEponymCategoriesLabel:(UILabel *)newLabel
{
	if (newLabel != eponymCategoriesLabel) {
		[eponymCategoriesLabel release];
		eponymCategoriesLabel = [newLabel retain];
	}
}

- (UILabel *) dateCreatedLabel
{
	if (nil == dateCreatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
		CGFloat labelWidth = fullWidth - 2 * pLabelSideMargin;
		CGRect createdRect = CGRectMake(pLabelSideMargin, pDistanceDateLabelsFromCat, labelWidth, 16.0);
		
		self.dateCreatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateCreatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateCreatedLabel.textColor = [UIColor darkGrayColor]; 
		dateCreatedLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		dateCreatedLabel.backgroundColor = [UIColor clearColor];
	}
	return dateCreatedLabel;
}
- (void) setDateCreatedLabel:(UILabel *)newLabel
{
	if (newLabel != dateCreatedLabel) {
		[dateCreatedLabel release];
		dateCreatedLabel = [newLabel retain];
	}
}

- (UILabel *) dateUpdatedLabel
{
	if (nil == dateUpdatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
		CGFloat labelWidth = fullWidth - 2 * pLabelSideMargin;
		CGRect createdRect = CGRectMake(pLabelSideMargin, pDistanceDateLabelsFromCat, labelWidth, 16.0);
		
		self.dateUpdatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateUpdatedLabel.textColor = [UIColor darkGrayColor]; 
		dateUpdatedLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		dateUpdatedLabel.backgroundColor = [UIColor clearColor];
	}
	return dateUpdatedLabel;
}
- (void) setDateUpdatedLabel:(UILabel *)newLabel
{
	if (newLabel != dateUpdatedLabel) {
		[dateUpdatedLabel release];
		dateUpdatedLabel = [newLabel retain];
	}
}
#pragma mark -



#pragma mark GUI
- (void) loadView
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	// The main view
	self.view = [[[UIScrollView alloc] initWithFrame:screenRect] autorelease];
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view.autoresizesSubviews = YES;
	
	[self.view addSubview:self.eponymTitleLabel];
	
	// Compose the container (contains eponym text, the category labels and the date labels)
	CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
	CGRect containerRect = CGRectMake(pSideMargin, pSideMargin + pHeightTitle + pDistanceTextFromTitle, fullWidth, 20.0);
	
	UIView *container = [[[UIView alloc] initWithFrame:containerRect] autorelease];
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
	container.autoresizesSubviews = YES;
	
	// add subviews to the container
	[container addSubview:self.eponymTextView];
	[container addSubview:self.eponymCategoriesLabel];
	[container addSubview:self.dateCreatedLabel];
	[container addSubview:self.dateUpdatedLabel];
	
	[self.view addSubview:container];
	
	// Google Ads
	[self adViewExists];
}

- (void) viewWillAppear:(BOOL)animated
{
	// starred or not starred, that's the question
	self.navigationItem.rightBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	
	// title and text
	eponymTitleLabel.text = eponymToBeShown.title;
	eponymTextView.text = eponymToBeShown.text;
	
	// categories
	if ([eponymToBeShown.categories count] > 0) {
		NSMutableArray *eponymCategories = [NSMutableArray arrayWithCapacity:[eponymToBeShown.categories count]];
		for (EponymCategory *cat in eponymToBeShown.categories) {
			[eponymCategories addObject:cat.tag];
		}
		eponymCategoriesLabel.text = [eponymCategories componentsJoinedByString:@", "];
	}
	else {
		eponymCategoriesLabel.text = nil;
	}
	
	// dates
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	if (eponymToBeShown.created) {
		dateCreatedLabel.hidden = NO;
		dateCreatedLabel.text = [NSString stringWithFormat:@"Created: %@", [dateFormatter stringFromDate:eponymToBeShown.created]];
	}
	else {
		dateCreatedLabel.hidden = YES;
	}
	
	if (eponymToBeShown.lastedit) {
		dateUpdatedLabel.hidden = NO;
		dateUpdatedLabel.text = [NSString stringWithFormat:@"Updated: %@", [dateFormatter stringFromDate:eponymToBeShown.lastedit]];
	}
	else {
		dateUpdatedLabel.hidden = YES;
	}
	
	// adjust content
	[self adjustDisplayToContent];
}

- (void) viewDidAppear:(BOOL)animated
{
	[self loadGoogleAdsWithEponym:eponymToBeShown];
}


- (void) adjustDisplayToContent
{
	// Size needed to fit all text
	CGRect currRect = eponymTextView.frame;
	CGSize szMax = CGSizeMake(currRect.size.width, 10000.0);
	CGSize optimalSize = [eponymTextView sizeThatFits:szMax];
	
	currRect.size.height = optimalSize.height;
	eponymTextView.frame = currRect;
	
	// Align the labels below
	CGRect catRect = eponymCategoriesLabel.frame;
	catRect.origin.y = currRect.size.height + pDistanceCatLabelFromText;
	eponymCategoriesLabel.frame = catRect;
	
	CGFloat newHeight = catRect.origin.y + catRect.size.height;
	
	if (!dateCreatedLabel.hidden) {
		CGRect creaRect = dateCreatedLabel.frame;
		creaRect.origin.y = newHeight + pDistanceDateLabelsFromCat;
		dateCreatedLabel.frame = creaRect;
		newHeight = creaRect.origin.y + creaRect.size.height;
	}
	
	if (!dateUpdatedLabel.hidden) {
		CGRect updRect = dateUpdatedLabel.frame;
		updRect.origin.y = newHeight;
		dateUpdatedLabel.frame = updRect;
		newHeight = updRect.origin.y + updRect.size.height;
	}
	
	// tell the container view his new height
	newHeight += pTotalSizeBottomMargin;
	CGRect superRect = eponymTextView.superview.frame;
	superRect.size.height = newHeight;
	eponymTextView.superview.frame = superRect;
	
	// adjust Google ads
	CGFloat googleY = superRect.origin.y + superRect.size.height + kGoogleAdViewTopMargin;
	CGRect adRect = CGRectMake(0.0, googleY, kGADAdSize320x50.width, kGADAdSize320x50.height);
	[self addGoogleAdsToView:self.view inRect:adRect];
	newHeight = googleY + adRect.size.height;
	
	// tell our view the size so that scrolling is possible
	CGFloat minHeight = [[UIScreen mainScreen] applicationFrame].size.height;
	CGSize contSize = CGSizeMake(((UIScrollView *)self.view).contentSize.width, newHeight);
	((UIScrollView *)self.view).contentSize = contSize;
	
	// scroll to top when needed
	if (newHeight < minHeight) {
		[((UIScrollView *)self.view) scrollRectToVisible:CGRectMake(0.0, 0.0, 10.0, 10.0) animated:NO];
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
	if (((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate) {
		return YES;
	}
	
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation
{
	[self adjustDisplayToContent];
}

- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];	// Releases the view if it doesn't have a superview
}
#pragma mark -



#pragma mark Toggle Starred
- (void) toggleEponymStarred
{
	[eponymToBeShown toggleStarred];
	self.navigationItem.rightBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	if (eponymToBeShown.eponymCell) {
		if ([eponymToBeShown.eponymCell respondsToSelector:@selector(imageView)]) {
			[[eponymToBeShown.eponymCell imageView] setImage:eponymToBeShown.starred ? [delegate starImageListActive] : nil];
		}
		else {
			eponymToBeShown.eponymCell.image = eponymToBeShown.starred ? [delegate starImageListActive] : nil;
		}
	}
}
#pragma mark -



#pragma mark Google Ads
- (BOOL) adViewExists
{
	if (!((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).showGoogleAds) {
		return NO;
	}
	
	if (nil == adController) {
		self.adController = [[[GADAdViewController alloc] initWithDelegate:self] autorelease];
		adController.adSize = kGADAdSize320x50;
		adController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	}
	return (nil != adController);
}

- (void) addGoogleAdsToView:(UIView *)toView inRect:(CGRect)inRect
{
	if ([self adViewExists]) {
		UIView *oldSuperview = [adController.view superview];
		if (nil != oldSuperview && oldSuperview != toView) {
			[adController.view removeFromSuperview];
			oldSuperview = nil;
		}
		
		adController.view.frame = inRect;
		if (nil == oldSuperview) {
			[toView addSubview:adController.view];
		}
	}
}

- (void) loadGoogleAdsWithEponym:(Eponym *)eponym
{
	if ([self adViewExists]) {
		NSMutableArray *categoryStrings = [NSMutableArray arrayWithCapacity:[eponym.categories count]];
		for (EponymCategory *cat in eponym.categories) {
			[categoryStrings addObject:[cat.title stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
		}
		NSString *myKeywords = [NSString stringWithFormat:
								@"medical,eponyms,%@,%@",
								[categoryStrings componentsJoinedByString:@","],
								eponym.keywordTitle];
		//NSLog(@"Google Ad keywords: %@", myKeywords);
		// **************************************************************************
		// Please replace the kGADAdSenseClientID, kGADAdSenseKeywords, and
		// kGADAdSenseChannelIDs values with your own AdSense client ID, keywords,
		// and channel IDs respectively. If this application has an associated
		// iPhone website, then set the site's URL using kGADAdSenseAppWebContentURL
		// for improved ad targeting.
		//
		// PLEASE DO NOT CLICK ON THE AD UNLESS YOU ARE IN TEST MODE. OTHERWISE, YOUR
		// ACCOUNT MAY BE DISABLED.
		// **************************************************************************
		NSNumber *channel = [NSNumber numberWithUnsignedLongLong:6892341229];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									kGoogleAdSenseClientID, kGADAdSenseClientID,
									@"Pascal Pfiffner", kGADAdSenseCompanyName,
									@"Eponyms", kGADAdSenseAppName,
									myKeywords, kGADAdSenseKeywords,
									[NSArray arrayWithObject:channel], kGADAdSenseChannelIDs,
									[UIColor colorWithWhite:0.9 alpha:1.0], kGADAdSenseAdBackgroundColor,
									[UIColor colorWithWhite:0.6 alpha:1.0], kGADAdSenseAdBorderColor,
									[UIColor blackColor], kGADAdSenseAdLinkColor,
									[UIColor darkGrayColor], kGADAdSenseAdTextColor,
									[UIColor colorWithRed:0.0 green:0.25 blue:0.5 alpha:1.0], kGADAdSenseAdURLColor,
									[NSNumber numberWithInt:1], kGADAdSenseIsTestAdRequest,
									nil];
		[adController loadGoogleAd:attributes];
	}
}

- (GADAdClickAction) adControllerActionModelForAdClick:(GADAdViewController *)anAdController
{
	return GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW;
}
/*
- (void) adControllerDidFinishLoading:(GADAdViewController *)anAdController
{
	NSLog(@"ad controller finished: %@", anAdController);
}	//	*/

- (void) adController:(GADAdViewController *)anAdController failedWithError:(NSError *)error
{
	[anAdController.view removeFromSuperview];
}


@end
