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
#import "PPHintableLabel.h"
#import "PPHintView.h"
#ifdef SHOW_GOOGLE_ADS
#import "GADAdSenseParameters.h"
#import "GoogleAdSenseClient.h"
#endif


#define kSideMargin 15.0
#define kLabelSideMargin 5.0
#define kHeightTitle 32.0
#define kDistanceTextFromTitle 8.0
#define kDistanceCatLabelFromText 8.0
#define kDistanceDateLabelsFromCat 8.0
#define kTotalSizeBottomMargin 10.0
#define kGoogleAdViewTopMargin 0.0			// additionally to kTotalSizeBottomMargin
#define kBottomMargin 5.0					// does not apply to the Google Ads




@interface EponymViewController ()

- (void) adjustInterfaceToEponym;
- (void) alignUIElements;

#ifdef SHOW_GOOGLE_ADS
@property (nonatomic, readwrite, retain) GADAdViewController *adController;

- (BOOL) adViewIsVisible;
- (BOOL) adViewExists;
- (void) addGoogleAdsToView:(UIView *)toView inRect:(CGRect)inRect;
- (void) loadGoogleAdsWithEponym:(Eponym *)eponym;
#endif

@end



@implementation EponymViewController

@synthesize delegate;
@dynamic eponymToBeShown;
@dynamic rightBarButtonStarredItem;
@dynamic rightBarButtonNotStarredItem;
@dynamic eponymTitleLabel;
@dynamic eponymTextView;
@dynamic eponymCategoriesLabel;
@dynamic dateCreatedLabel;
@dynamic dateUpdatedLabel;
@dynamic revealButton;
@synthesize displayNextEponymInLearningMode;
#ifdef SHOW_GOOGLE_ADS
@synthesize adController;
#endif


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = @"Eponym";
	}
	return self;
}

- (void) dealloc
{
	self.eponymToBeShown = nil;
	
	self.rightBarButtonStarredItem = nil;
	self.rightBarButtonNotStarredItem = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	self.revealButton = nil;
	
#ifdef SHOW_GOOGLE_ADS
	self.adController = nil;
#endif
	
	[super dealloc];
}

- (void) viewDidUnload
{
	self.rightBarButtonStarredItem = nil;
	self.rightBarButtonNotStarredItem = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	self.revealButton = nil;
	
#ifdef SHOW_GOOGLE_ADS
	self.adController = nil;
#endif
	
	[super viewDidUnload];
}
#pragma mark -



#pragma mark KVC
- (Eponym *) eponymToBeShown
{
	return eponymToBeShown;
}
- (void) setEponymToBeShown:(Eponym *)newEponym
{
	if (newEponym != eponymToBeShown) {
		[eponymToBeShown release];
		eponymToBeShown = [newEponym retain];
		
		if (nil != eponymToBeShown) {
#ifdef SHOW_GOOGLE_ADS
			adIsLoading = NO;
			adDidLoad = NO;
			if ([self adViewIsVisible]) {
				[self performSelector:@selector(loadGoogleAdsWithEponym:) withObject:eponymToBeShown afterDelay:0.4];
			}
#endif
			[self adjustInterfaceToEponym];
		}
	}
}

- (UIBarButtonItem *) rightBarButtonStarredItem
{
	if (nil == rightBarButtonStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[delegate starImageEponymActive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
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
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
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
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect titleRect = CGRectMake(kSideMargin, kSideMargin, fullWidth, kHeightTitle);
		
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
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect textRect = CGRectMake(0.0, 0.0, fullWidth, 40.0);
		
		self.eponymTextView = [[[MCTextView alloc] initWithFrame:textRect] autorelease];
		eponymTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymTextView.userInteractionEnabled = YES;
		eponymTextView.scrollEnabled = NO;
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

- (PPHintableLabel *) eponymCategoriesLabel
{
	if (nil == eponymCategoriesLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect catRect = CGRectMake(kLabelSideMargin, kDistanceCatLabelFromText, labelWidth, 19.0);
		
		self.eponymCategoriesLabel = [[[PPHintableLabel alloc] initWithFrame:catRect] autorelease];
		eponymCategoriesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		eponymCategoriesLabel.adjustsFontSizeToFitWidth = YES;
		eponymCategoriesLabel.minimumFontSize = 12.0;
		eponymCategoriesLabel.font = [UIFont systemFontOfSize:17.0];
		eponymCategoriesLabel.backgroundColor = [UIColor clearColor];
		eponymCategoriesLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
		eponymCategoriesLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return eponymCategoriesLabel;
}
- (void) setEponymCategoriesLabel:(PPHintableLabel *)newLabel
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
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateCreatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateCreatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateCreatedLabel.textColor = [UIColor darkGrayColor]; 
		dateCreatedLabel.font = [UIFont systemFontOfSize:14.0];
		dateCreatedLabel.backgroundColor = [UIColor clearColor];
		dateCreatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		dateCreatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
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
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateUpdatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
		dateUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		dateUpdatedLabel.textColor = [UIColor darkGrayColor]; 
		dateUpdatedLabel.font = [UIFont systemFontOfSize:14.0];
		dateUpdatedLabel.backgroundColor = [UIColor clearColor];
		dateUpdatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		dateUpdatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
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

- (UIButton *) revealButton
{
	if (nil == revealButton) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat buttonWidth = 70.0;
		CGRect buttonRect = CGRectMake(fullWidth - buttonWidth, kDistanceDateLabelsFromCat, buttonWidth, 37.0);
		
		self.revealButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[revealButton setTitle:@"Solve"
					  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[revealButton setTitleColor:[UIColor colorWithRed:0.0 green:0.25 blue:0.5 alpha:1.0] forState:UIControlStateNormal];
		
		// background image
		UIImage *buttonImage = [[UIImage imageNamed:@"BlueRoundedButton.png"] stretchableImageWithLeftCapWidth:8.0 topCapHeight:8.0];
		[revealButton setBackgroundImage:buttonImage
								forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		
		// action
		[revealButton addTarget:self action:@selector(reveal:) forControlEvents:UIControlEventTouchUpInside];
		
		// properties
		revealButton.frame = buttonRect;
		revealButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	}
	return revealButton;
}
- (void) setRevealButton:(UIButton *)newButton
{
	if (newButton != revealButton) {
		[revealButton release];
		revealButton = [newButton retain];
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
	((UIScrollView *)self.view).delegate = self;
	
	[self.view addSubview:self.eponymTitleLabel];
	
	// Compose the container (contains eponym text, the category labels and the date labels)
	CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
	CGRect containerRect = CGRectMake(kSideMargin, kSideMargin + kHeightTitle + kDistanceTextFromTitle, fullWidth, 20.0);
	
	UIView *container = [[[UIView alloc] initWithFrame:containerRect] autorelease];
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
	container.autoresizesSubviews = YES;
	
	// add subviews to the container
	[container addSubview:self.eponymTextView];
	[container addSubview:self.eponymCategoriesLabel];
	[container addSubview:self.dateCreatedLabel];
	[container addSubview:self.dateUpdatedLabel];
	[container addSubview:self.revealButton];
	
	[self.view addSubview:container];
	
	// Google Ads
#ifdef SHOW_GOOGLE_ADS
	[self adViewExists];
#endif
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self alignUIElements];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	viewIsVisible = YES;
#ifdef SHOW_GOOGLE_ADS
	if ([self adViewIsVisible]) {
		[self loadGoogleAdsWithEponym:eponymToBeShown];
	}
#endif
}

- (void) viewWillDisappear:(BOOL)animated
{
	viewIsVisible = NO;
	[super viewWillDisappear:animated];
}


- (void) alignUIElements
{
	CGRect viewFrame = self.view.frame;
	
	// Size needed to fit all text
	CGRect currRect = eponymTextView.frame;
	CGSize szMax = CGSizeMake(currRect.size.width, 10000.0);
	CGSize optimalSize = [eponymTextView sizeThatFits:szMax];
	
	if (optimalSize.height < 10000.0) {
		currRect.size.height = optimalSize.height;
	}
	eponymTextView.frame = currRect;
	
	// Align the labels below
	CGRect catRect = eponymCategoriesLabel.frame;
	catRect.origin.x = currRect.origin.x + kLabelSideMargin;
	catRect.origin.y = currRect.size.height + kDistanceCatLabelFromText;
	catRect.size.width = [eponymCategoriesLabel.text sizeWithFont:eponymCategoriesLabel.font].width;
	eponymCategoriesLabel.frame = catRect;
	
	CGFloat subviewHeight = catRect.origin.y + catRect.size.height;
	
	if (!dateCreatedLabel.hidden) {
		CGRect creaRect = dateCreatedLabel.frame;
		creaRect.origin.y = subviewHeight + kDistanceDateLabelsFromCat;
		dateCreatedLabel.frame = creaRect;
		subviewHeight = creaRect.origin.y + creaRect.size.height;
	}
	
	if (!dateUpdatedLabel.hidden) {
		CGRect updRect = dateUpdatedLabel.frame;
		updRect.origin.y = subviewHeight + 1.0;
		dateUpdatedLabel.frame = updRect;
		subviewHeight = updRect.origin.y + updRect.size.height;
	}
	
	if (!revealButton.hidden) {
		CGRect buttRect = revealButton.frame;
		buttRect.origin.y = catRect.origin.y + catRect.size.height + kDistanceDateLabelsFromCat;
		revealButton.frame = buttRect;
	}
	
	// tell the container view his new height
	subviewHeight += kTotalSizeBottomMargin;
	CGRect superRect = eponymTextView.superview.frame;
	superRect.size.height = subviewHeight;
	eponymTextView.superview.frame = superRect;
	
	CGFloat totalHeight = superRect.origin.y + superRect.size.height + kBottomMargin;
	
	// adjust Google ads
#ifdef SHOW_GOOGLE_ADS
	if ([self adViewExists]) {
		CGFloat googleMin = viewFrame.size.height - kGADAdSize320x50.height;
		CGFloat googleY = superRect.origin.y + superRect.size.height + kGoogleAdViewTopMargin;
		CGFloat googleTop = fmaxf(googleY, googleMin);
		CGRect adRect = CGRectMake(0.0, googleTop, kGADAdSize320x50.width, kGADAdSize320x50.height);
		[self addGoogleAdsToView:self.view inRect:adRect];
		totalHeight = googleTop + adRect.size.height;
	}
#endif
	
	// tell our view the size so that scrolling is possible
	CGFloat minHeight = viewFrame.size.height;
	CGSize contSize = CGSizeMake(((UIScrollView *)self.view).contentSize.width, totalHeight);
	((UIScrollView *)self.view).contentSize = contSize;
	
	// scroll to top when needed
	if (totalHeight < minHeight) {
		[((UIScrollView *)self.view) scrollRectToVisible:CGRectMake(0.0, 0.0, 10.0, 10.0) animated:NO];
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate) {
		if (nil != eponymCategoriesLabel.hintViewDisplayed) {
			[eponymCategoriesLabel.hintViewDisplayed hide];
		}
		return YES;
	}
	
	return IS_PORTRAIT(toInterfaceOrientation);
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation
{
	[self alignUIElements];
#ifdef SHOW_GOOGLE_ADS
	if (!adIsLoading && !adDidLoad && [self adViewIsVisible]) {
		[self loadGoogleAdsWithEponym:eponymToBeShown];
	}
#endif
}
#pragma mark -



#pragma mark Eponym Display
- (void) adjustInterfaceToEponym
{
	((UIScrollView *)self.view).contentOffset = CGPointZero;
	
	// starred or not starred, that's the question
	self.navigationItem.rightBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	
	// title and text
	eponymTitleLabel.text = (-1 == displayNextEponymInLearningMode) ? @"…" : eponymToBeShown.title;
	eponymTextView.text = (1 == displayNextEponymInLearningMode) ? @"…" : eponymToBeShown.text;
	eponymTextView.contentOffset = CGPointZero;
	[eponymTextView resignFirstResponder];
	
	// categories
	if ([eponymToBeShown.categories count] > 0) {
		NSMutableArray *eponymCategories = [NSMutableArray arrayWithCapacity:[eponymToBeShown.categories count]];
		NSMutableArray *eponymCategoriesDesc = [NSMutableArray arrayWithCapacity:[eponymToBeShown.categories count]];
		for (EponymCategory *cat in eponymToBeShown.categories) {
			[eponymCategories addObject:cat.tag];
			[eponymCategoriesDesc addObject:[NSString stringWithFormat:@"%@ • %@", cat.tag, cat.title]];
		}
		eponymCategoriesLabel.text = [eponymCategories componentsJoinedByString:@", "];
		eponymCategoriesLabel.hintText = [eponymCategoriesDesc componentsJoinedByString:@"\n"];
	}
	else {
		eponymCategoriesLabel.text = @"";
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
	
	// reveal button
	revealButton.hidden = (0 == displayNextEponymInLearningMode);
	displayNextEponymInLearningMode = 0;
	
	// adjust content
	[self alignUIElements];
}

- (IBAction) reveal:(id)sender
{
	eponymTitleLabel.text = eponymToBeShown.title;
	eponymTextView.text = eponymToBeShown.text;
	
	[UIView beginAnimations:nil context:nil];
	revealButton.hidden = YES;
	[self alignUIElements];
	[UIView commitAnimations];
}
#pragma mark -



#pragma mark Toggle Starred
- (void) toggleEponymStarred:(id)sender
{
	[eponymToBeShown toggleStarred];
	self.navigationItem.rightBarButtonItem = eponymToBeShown.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	if (eponymToBeShown.eponymCell) {
		eponymToBeShown.eponymCell.imageView.image = eponymToBeShown.starred ? [delegate starImageListActive] : nil;
	}
}
#pragma mark -



#pragma mark Scroll View Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
#ifdef SHOW_GOOGLE_ADS
	if (!adIsLoading && !adDidLoad && [self adViewIsVisible]) {
		[self loadGoogleAdsWithEponym:eponymToBeShown];
	}
#endif
}
#pragma mark -



#ifdef SHOW_GOOGLE_ADS
#pragma mark Google Ads
- (BOOL) adViewIsVisible
{
	BOOL adIsVisible = NO;
	if (viewIsVisible && [self adViewExists]) {
		UIScrollView *scrollView = (UIScrollView *)self.view;
		CGFloat adMiddle = adController.view.frame.origin.y + (adController.view.frame.size.height / 2);
		CGFloat lowestVisible = scrollView.frame.size.height + scrollView.contentOffset.y;
		adIsVisible = (adMiddle <= lowestVisible);
	}
	return adIsVisible;
}

- (BOOL) adViewExists
{
	if (nil != adController) {
		return YES;
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
	if (!adIsLoading && !adDidLoad && [self adViewExists]) {
		NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
		if (now < adsAreRefractoryUntil) {
			return;
		}
		adsAreRefractoryUntil = now + 10.0;					// at max load a new ad every 10 seconds
		
		adIsLoading = YES;
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
		NSNumber *channel = [NSNumber numberWithUnsignedLongLong:kGoogleAdSenseChannelID];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									kGoogleAdSenseClientID, kGADAdSenseClientID,
									kGoogleAdSenseCompanyName, kGADAdSenseCompanyName,
									kGoogleAdSenseAppName, kGADAdSenseAppName,
									myKeywords, kGADAdSenseKeywords,
									[NSArray arrayWithObject:channel], kGADAdSenseChannelIDs,
									[UIColor colorWithWhite:0.9 alpha:1.0], kGADAdSenseAdBackgroundColor,
									[UIColor colorWithWhite:0.6 alpha:1.0], kGADAdSenseAdBorderColor,
									[UIColor blackColor], kGADAdSenseAdLinkColor,
									[UIColor darkGrayColor], kGADAdSenseAdTextColor,
									[UIColor colorWithRed:0.0 green:0.25 blue:0.5 alpha:1.0], kGADAdSenseAdURLColor,
									[NSNumber numberWithInt:0], kGADAdSenseIsTestAdRequest,
									nil];
		[adController loadGoogleAd:attributes];
	}
}

- (GADAdClickAction) adControllerActionModelForAdClick:(GADAdViewController *)anAdController
{
	return GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW;
}

- (void) adControllerDidFinishLoading:(GADAdViewController *)anAdController
{
	adDidLoad = YES;
}

- (void) adController:(GADAdViewController *)anAdController failedWithError:(NSError *)error
{
	[anAdController.view removeFromSuperview];
}
#endif


@end
