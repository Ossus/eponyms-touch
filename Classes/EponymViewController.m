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


#import "AppDelegate.h"
#import "EponymViewController.h"
#import "ListViewController.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "MCTextView.h"
#import "PPHintableLabel.h"
#import "PPHintView.h"
#ifdef SHOW_ADS
#	import "SMAATOConfig.h"
#	import <iSoma/SOMABannerView.h>
#	import <iSoma/SOMAGlobalSettings.h>
#	import <iSoma/SOMAUserSettings.h>
#endif


#define kSideMargin 15.f
#define kLabelSideMargin 5.f
#define kHeightTitle 32.f
#define kDistanceTextFromTitle 8.f
#define kDistanceCatLabelFromText 8.f
#define kDistanceDateLabelsFromCat 8.f
#define kTotalSizeBottomMargin 10.f
#define kBottomMargin 5.f




@interface EponymViewController ()

- (void)adjustInterfaceToEponymAnimated:(BOOL)animated;
- (void)alignUIElementsAnimated:(BOOL)animated;
- (void)showRandomEponym:(id)sender;

#ifdef SHOW_ADS
@property (nonatomic, strong) SOMABannerView *adView;

- (void)loadNewAdFor:(Eponym *)eponym;
#endif

@end



@implementation EponymViewController


- (void)viewDidUnload
{
	self.rightBarButtonStarredItem = nil;
	self.rightBarButtonNotStarredItem = nil;
	
	self.eponymTitleLabel = nil;
	self.eponymTextView = nil;
	self.eponymCategoriesLabel = nil;
	self.dateCreatedLabel = nil;
	self.dateUpdatedLabel = nil;
	self.randomNoTitleEponymButton = nil;
	self.randomNoTextEponymButton = nil;
	self.revealButton = nil;
	
	[super viewDidUnload];
}


- (id)init
{
	return [self initWithNibName:nil bundle:nil];
}



#pragma mark-  GUI
- (void)loadView
{
	self.title = @"Eponym";
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	// The main view
	self.view = [[UIScrollView alloc] initWithFrame:screenRect];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.view.backgroundColor = [UIColor colorWithRed:0.936f green:0.953f blue:0.968f alpha:1.f];
	}
	else {
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-vertical.png"]];
	}
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view.autoresizesSubviews = YES;
	((UIScrollView *)self.view).delegate = self;
	
	[self.view addSubview:self.eponymTitleLabel];
	
	// Compose the container (contains eponym text, the category labels and the date labels)
	CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
	CGRect containerRect = CGRectMake(kSideMargin, kSideMargin + kHeightTitle + kDistanceTextFromTitle, fullWidth, 20.0);
	
	UIView *container = [[UIView alloc] initWithFrame:containerRect];
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
	container.autoresizesSubviews = YES;
	
	// add subviews to the container
	[container addSubview:self.eponymTextView];
	[container addSubview:self.eponymCategoriesLabel];
	[container addSubview:self.dateCreatedLabel];
	[container addSubview:self.dateUpdatedLabel];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[container addSubview:self.randomNoTitleEponymButton];
		[container addSubview:self.randomNoTextEponymButton];
	}
	[self.view addSubview:container];
	
	// ads?
#ifdef SHOW_ADS
	self.adView = [[SOMABannerView alloc] initWithDimension:kSOMAAdDimensionDefault];
	[_adView adSettings].adspaceId = kSMAATOAdSpaceId;
	[_adView adSettings].publisherId = kSMAATOPublisherId;
	[self.view addSubview:_adView];
	
	[_adView addAdListener:self];
#endif
	
	[self adjustInterfaceToEponymAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self alignUIElementsAnimated:NO];
	
#ifdef SHOW_ADS
	[self loadNewAdFor:_eponym];
#endif
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	viewIsVisible = YES;
#ifdef SHOW_ADS
	[_adView setAutoReloadEnabled:YES];
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifdef SHOW_ADS
	[_adView setAutoReloadEnabled:NO];
#endif
	viewIsVisible = NO;
	[super viewWillDisappear:animated];
}


/**
 *  iOS 5 and prior
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self alignUIElementsAnimated:YES];
}



#pragma mark - Eponym Display
- (void)adjustInterfaceToEponymAnimated:(BOOL)animated
{
	((UIScrollView *)self.view).contentOffset = CGPointZero;
	
	// starred or not starred, that's the question
	[self indicateEponymStarredStatus];
	
	// title and text
	_eponymTitleLabel.text = _eponym ? ((EPLearningModeNoTitle == _displayNextEponymInLearningMode) ? @"…" : _eponym.title) : @"No eponym";
	_eponymTitleLabel.textColor = _eponym ? [UIColor blackColor] : [UIColor darkGrayColor];
	_eponymTextView.text = _eponym ? (EPLearningModeNoText == _displayNextEponymInLearningMode) ? @"…" : _eponym.text : @"Choose an eponym from the list to your left";
	_eponymTextView.contentOffset = CGPointZero;
	[_eponymTextView resignFirstResponder];
	
	// enable revealButton
	if (EPLearningModeNoTitle == _displayNextEponymInLearningMode) {
		self.revealButton.frame = _eponymTitleLabel.bounds;
		[_eponymTitleLabel addSubview:_revealButton];
	}
	else if (EPLearningModeNoText == _displayNextEponymInLearningMode) {
		self.revealButton.frame = _eponymTextView.bounds;
		[_eponymTextView addSubview:_revealButton];
	}
	
	// categories
	if ([_eponym.categories count] > 0) {
		NSMutableArray *eponymCategories = [NSMutableArray arrayWithCapacity:[_eponym.categories count]];
		NSMutableArray *eponymCategoriesDesc = [NSMutableArray arrayWithCapacity:[_eponym.categories count]];
		for (EponymCategory *cat in _eponym.categories) {
			[eponymCategories addObject:cat.tag];
			[eponymCategoriesDesc addObject:[NSString stringWithFormat:@"%@ • %@", cat.tag, cat.title]];
		}
		_eponymCategoriesLabel.text = [eponymCategories componentsJoinedByString:@", "];
		_eponymCategoriesLabel.hintText = [eponymCategoriesDesc componentsJoinedByString:@"\n"];
	}
	else {
		_eponymCategoriesLabel.text = @"";
	}
	
	// dates
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	if (_eponym.created) {
		_dateCreatedLabel.hidden = NO;
		_dateCreatedLabel.text = [NSString stringWithFormat:@"Created: %@", [dateFormatter stringFromDate:_eponym.created]];
	}
	else {
		_dateCreatedLabel.hidden = YES;
	}
	
	if (_eponym.lastedit) {
		_dateUpdatedLabel.hidden = NO;
		_dateUpdatedLabel.text = [NSString stringWithFormat:@"Updated: %@", [dateFormatter stringFromDate:_eponym.lastedit]];
	}
	else {
		_dateUpdatedLabel.hidden = YES;
	}
	
	// adjust content
	[self alignUIElementsAnimated:animated];
	
	_displayNextEponymInLearningMode = EPLearningModeNone;
}

- (void)alignUIElementsAnimated:(BOOL)animated
{
	CGRect viewFrame = self.view.frame;
	CGFloat scaleFactor = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1.5f : 1.f;
	
	// Size needed to fit all text
	CGRect textFrame = _eponymTextView.frame;
	CGSize szMax = CGSizeMake(textFrame.size.width, 10000.0);
	CGSize optimalSize = [_eponymTextView sizeThatFits:szMax];
	
	if (optimalSize.height < 10000.0) {
		textFrame.size.height = optimalSize.height;
	}
	
	// Align the labels below
	CGRect catRect = _eponymCategoriesLabel.frame;
	catRect.size.width = [_eponymCategoriesLabel.text sizeWithFont:_eponymCategoriesLabel.font].width;
	_eponymCategoriesLabel.frame = catRect;
	
	catRect.origin.x = textFrame.origin.x + kLabelSideMargin;
	catRect.origin.y = textFrame.size.height + roundf(kDistanceCatLabelFromText * scaleFactor);
	
	CGFloat subviewHeight = catRect.origin.y + catRect.size.height;
	
	CGRect creaRect = _dateCreatedLabel.frame;
	creaRect.origin.y = subviewHeight + roundf(kDistanceDateLabelsFromCat * scaleFactor);
	if (!_dateCreatedLabel.hidden) {
		subviewHeight = creaRect.origin.y + creaRect.size.height;
	}
	
	CGRect updRect = _dateUpdatedLabel.frame;
	updRect.origin.y = subviewHeight + 1.f;
	if (!_dateUpdatedLabel.hidden) {
		subviewHeight = updRect.origin.y + updRect.size.height;
	}
	
	// "random eponym" buttons on iPad
	CGRect rand1Frame = _randomNoTitleEponymButton.frame;
	CGRect rand2Frame = _randomNoTextEponymButton.frame;
	if (_randomNoTitleEponymButton && _randomNoTextEponymButton) {
		CGFloat orig = subviewHeight + roundf(kDistanceDateLabelsFromCat * scaleFactor);
		rand1Frame.origin.y = orig;
		rand2Frame.origin.y = orig;
		
		subviewHeight = orig + rand1Frame.size.height;
	}
	
	// tell the container view its new height
	subviewHeight += kTotalSizeBottomMargin;
	CGRect superRect = [_eponymTextView superview].frame;
	superRect.size.height = subviewHeight;
	[_eponymTextView superview].frame = superRect;
	
	CGFloat totalHeight = superRect.origin.y + superRect.size.height + kBottomMargin;
	
	// align ads
#ifdef SHOW_ADS
	CGRect adRect = CGRectZero;
	if ([_adView superview]) {
		CGSize adSize = [_adView frame].size;
		CGFloat minY = viewFrame.size.height - adSize.height;
		CGFloat targetY = superRect.origin.y + superRect.size.height;
		CGFloat top = fmaxf(targetY, minY);
		
		adRect = CGRectMake(0.f, top, adSize.width, adSize.height);
		
		totalHeight = adRect.origin.y + adRect.size.height;
	}
#endif
	
	// tell our view the size so that scrolling is possible
	CGFloat minHeight = viewFrame.size.height;
	CGSize contSize = CGSizeMake(((UIScrollView *)self.view).contentSize.width, totalHeight);
	((UIScrollView *)self.view).contentSize = contSize;
	
	// scroll to top when needed
	if (totalHeight < minHeight) {
		[((UIScrollView *)self.view) scrollRectToVisible:CGRectMake(0.f, 0.f, 10.f, 10.f) animated:NO];
	}
	
	// animated selected changes
	[UIView animateWithDuration:(animated ? 0.2 : 0.0)
					 animations:^{
						 
						 // text view
						 _eponymTextView.frame = textFrame;
						 
						 // categories
						 _eponymCategoriesLabel.frame = catRect;
						 
						 // dates
						 _dateCreatedLabel.frame = creaRect;
						 _dateUpdatedLabel.frame = updRect;
						 
						 // "random" buttons
						 _randomNoTitleEponymButton.frame = rand1Frame;
						 _randomNoTextEponymButton.frame = rand2Frame;
						 
						 // ads
#ifdef SHOW_ADS
						 _adView.frame = adRect;
#endif
					 }];
}


- (void)showRandomEponym:(id)sender
{
	if (_randomNoTitleEponymButton == sender) {
		[APP_DELEGATE loadRandomEponymWithMode:EPLearningModeNoTitle];
	}
	else {
		[APP_DELEGATE loadRandomEponymWithMode:EPLearningModeNoText];
	}
}

- (IBAction)reveal:(id)sender
{
	[_revealButton removeFromSuperview];
	[APP_DELEGATE resetEponymRefractoryTimeout];
	[[APP_DELEGATE listController] assureEponymSelectedInListAnimated:NO];
	
	_eponymTitleLabel.text = _eponym.title;
	_eponymTitleLabel.textColor = [UIColor blackColor];
	_eponymTextView.text = _eponym.text;
	//eponymTextView.text = [NSString stringWithFormat:@"%@ %@ %@ %@", eponymToBeShown.text, eponymToBeShown.text, eponymToBeShown.text, eponymToBeShown.text];		// to test long eponyms
	
	 [self alignUIElementsAnimated:YES];
}



#pragma mark - Toggle Starred
- (void)toggleEponymStarred:(id)sender
{
	[_eponym toggleStarred];
	[self indicateEponymStarredStatus];
	[[APP_DELEGATE listController] assureSelectedEponymStarredInList];
}

- (void)indicateEponymStarredStatus
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.leftBarButtonItem = _eponym.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	}
	else {
		self.navigationItem.rightBarButtonItem = _eponym.starred ? self.rightBarButtonStarredItem : self.rightBarButtonNotStarredItem;
	}
}



#pragma mark - KVC
- (void)setEponym:(Eponym *)newEponym
{
	if (newEponym != _eponym) {
		_eponym = newEponym;
		
		if (_eponym) {
			[self adjustInterfaceToEponymAnimated:NO];
		}
	}
}

- (void)setEponym:(Eponym *)newEponym animated:(BOOL)animated
{
	if (newEponym != _eponym) {
		_eponym = newEponym;
		
		if (_eponym) {
			[self adjustInterfaceToEponymAnimated:animated];
		}
	}
}

- (UIBarButtonItem *)rightBarButtonStarredItem
{
	if (!_rightBarButtonStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[APP_DELEGATE starImageEponymActive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonStarredItem = [[UIBarButtonItem alloc] initWithCustomView:myButton];
	}
	return _rightBarButtonStarredItem;
}

- (UIBarButtonItem *)rightBarButtonNotStarredItem
{
	if (!_rightBarButtonNotStarredItem) {
		CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
		
		UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[myButton setImage:[APP_DELEGATE starImageEponymInactive]
				  forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[myButton addTarget:self action:@selector(toggleEponymStarred:) forControlEvents:UIControlEventTouchUpInside];
		myButton.showsTouchWhenHighlighted = YES;
		myButton.frame = buttonSize;
		
		self.rightBarButtonNotStarredItem = [[UIBarButtonItem alloc] initWithCustomView:myButton];
	}
	return _rightBarButtonNotStarredItem;
}

- (UILabel *)eponymTitleLabel
{
	if (!_eponymTitleLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect titleRect = CGRectMake(kSideMargin, kSideMargin, fullWidth, kHeightTitle);
		
		self.eponymTitleLabel = [[UILabel alloc] initWithFrame:titleRect];
		_eponymTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_eponymTitleLabel.userInteractionEnabled = YES;
		_eponymTitleLabel.font = [UIFont boldSystemFontOfSize:24.f];
		_eponymTitleLabel.numberOfLines = 1;
		_eponymTitleLabel.adjustsFontSizeToFitWidth = YES;
		_eponymTitleLabel.minimumFontSize = 12.f;
		_eponymTitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		_eponymTitleLabel.backgroundColor = [UIColor clearColor];
		_eponymTitleLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
		_eponymTitleLabel.shadowOffset = CGSizeMake(0.f, 1.f);
	}
	return _eponymTitleLabel;
}

- (MCTextView *)eponymTextView
{
	if (!_eponymTextView) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGRect textRect = CGRectMake(0.f, 0.f, fullWidth, 40.f);
		
		self.eponymTextView = [[MCTextView alloc] initWithFrame:textRect];
		_eponymTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_eponymTextView.userInteractionEnabled = YES;
		_eponymTextView.scrollEnabled = NO;
		_eponymTextView.editable = NO;
		_eponymTextView.font = [UIFont systemFontOfSize:17.f];
		_eponymTextView.borderColor = [UIColor colorWithWhite:0.6f alpha:1.f];
	}
	return _eponymTextView;
}

- (PPHintableLabel *)eponymCategoriesLabel
{
	if (!_eponymCategoriesLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect catRect = CGRectMake(kLabelSideMargin, kDistanceCatLabelFromText, labelWidth, 19.f);
		
		self.eponymCategoriesLabel = [[PPHintableLabel alloc] initWithFrame:catRect];
		_eponymCategoriesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_eponymCategoriesLabel.adjustsFontSizeToFitWidth = YES;
		_eponymCategoriesLabel.minimumFontSize = 12.f;
		_eponymCategoriesLabel.font = [UIFont systemFontOfSize:17.f];
		_eponymCategoriesLabel.backgroundColor = [UIColor clearColor];
		_eponymCategoriesLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
		_eponymCategoriesLabel.shadowOffset = CGSizeMake(0.f, 1.f);
	}
	return _eponymCategoriesLabel;
}

- (UILabel *)dateCreatedLabel
{
	if (!_dateCreatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateCreatedLabel = [[UILabel alloc] initWithFrame:createdRect];
		_dateCreatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_dateCreatedLabel.textColor = [UIColor darkGrayColor]; 
		_dateCreatedLabel.font = [UIFont systemFontOfSize:14.0];
		_dateCreatedLabel.backgroundColor = [UIColor clearColor];
		_dateCreatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		_dateCreatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return _dateCreatedLabel;
}

- (UILabel *)dateUpdatedLabel
{
	if (!_dateUpdatedLabel) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat labelWidth = fullWidth - 2 * kLabelSideMargin;
		CGRect createdRect = CGRectMake(kLabelSideMargin, kDistanceDateLabelsFromCat, labelWidth, 18.0);
		
		self.dateUpdatedLabel = [[UILabel alloc] initWithFrame:createdRect];
		_dateUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_dateUpdatedLabel.textColor = [UIColor darkGrayColor]; 
		_dateUpdatedLabel.font = [UIFont systemFontOfSize:14.0];
		_dateUpdatedLabel.backgroundColor = [UIColor clearColor];
		_dateUpdatedLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		_dateUpdatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	}
	return _dateUpdatedLabel;
}

- (UIButton *)randomNoTitleEponymButton
{
	if (!_randomNoTitleEponymButton) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat buttonWidth = roundf((fullWidth - kSideMargin) / 2);
		CGRect buttonRect = CGRectMake(0.f, kDistanceDateLabelsFromCat, buttonWidth, 37.f);
		
		self.randomNoTitleEponymButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_randomNoTitleEponymButton setTitle:@"Random Eponym"
								   forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[_randomNoTitleEponymButton setTitleColor:[UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f] forState:UIControlStateNormal];
		[_randomNoTitleEponymButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		
		// background image
		UIImage *buttonImage = [[UIImage imageNamed:@"RoundedButton.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[_randomNoTitleEponymButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		UIImage *buttonHighImage = [[UIImage imageNamed:@"RoundedButtonBlue.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[_randomNoTitleEponymButton setBackgroundImage:buttonHighImage forState:UIControlStateHighlighted];
		
		// action
		[_randomNoTitleEponymButton addTarget:self action:@selector(showRandomEponym:) forControlEvents:UIControlEventTouchUpInside];
		
		// properties
		_randomNoTitleEponymButton.frame = buttonRect;
		_randomNoTitleEponymButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	}
	return _randomNoTitleEponymButton;
}

- (UIButton *)randomNoTextEponymButton
{
	if (!_randomNoTextEponymButton) {
		CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGFloat fullWidth = screenRect.size.width - 2 * kSideMargin;
		CGFloat buttonWidth = roundf(fullWidth / 2 - kSideMargin);
		CGRect buttonRect = CGRectMake(fullWidth - buttonWidth, kDistanceDateLabelsFromCat, buttonWidth, 37.f);
		
		self.randomNoTextEponymButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_randomNoTextEponymButton setTitle:@"Random Title"
								   forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		[_randomNoTextEponymButton setTitleColor:[UIColor colorWithRed:0.f green:0.25f blue:0.5f alpha:1.f] forState:UIControlStateNormal];
		[_randomNoTextEponymButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		
		// background image
		UIImage *buttonImage = [[UIImage imageNamed:@"RoundedButton.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[_randomNoTextEponymButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		UIImage *buttonHighImage = [[UIImage imageNamed:@"RoundedButtonBlue.png"] stretchableImageWithLeftCapWidth:15.f topCapHeight:15.f];
		[_randomNoTextEponymButton setBackgroundImage:buttonHighImage forState:UIControlStateHighlighted];
		
		// action
		[_randomNoTextEponymButton addTarget:self action:@selector(showRandomEponym:) forControlEvents:UIControlEventTouchUpInside];
		
		// properties
		_randomNoTextEponymButton.frame = buttonRect;
		_randomNoTextEponymButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	}
	return _randomNoTextEponymButton;
}

- (UIButton *)revealButton
{
	if (!_revealButton) {
		self.revealButton = [UIButton buttonWithType:UIButtonTypeCustom];
		
		// action and resizing
		[_revealButton addTarget:self action:@selector(reveal:) forControlEvents:UIControlEventTouchUpInside];
		_revealButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _revealButton;
}



#pragma mark - Ads
#ifdef SHOW_ADS
- (void)loadNewAdFor:(Eponym *)eponym
{
	if (!_adView) {
		return;
	}
	if (!eponym) {
		DLog(@"Did not get an eponym");
		return;
	}
	
	// at max load a new ad every 30 seconds
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	if (now < adsAreRefractoryUntil) {
		return;
	}
	adsAreRefractoryUntil = now + 30.0;
	
	// add keywords
	NSMutableArray *words = [NSMutableArray arrayWithCapacity:4];
	[words addObject:@"medical eponyms"];
	for (EponymCategory *cat in eponym.categories) {
		if (cat.title) {
			[words addObject:cat.title];
		}
	}
	[[SOMAGlobalSettings globalSettings] userSettings].keywordList = [words componentsJoinedByString:@" "];
	
	// request
	[_adView asyncLoadNewBanner];
}

- (void)onReceiveAd:(id<SOMAAdDownloaderProtocol>)sender withReceivedBanner:(id<SOMAReceivedBannerProtocol>)receivedBanner
{
	if ([receivedBanner status] == kSOMABannerStatusError) {
		DLog(@"Error with banner retrieval: %@", [receivedBanner errorMessage]);
	}
	else {
		DLog(@"Did receive a banner");
	}
}
#endif


@end
