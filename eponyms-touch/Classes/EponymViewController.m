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


#import "EponymViewController.h"
#import "Eponym.h"
#import "EponymTextView.h"


#define pSideMargin 10.0
#define pLabelSideMargin 5.0
#define pHeightTitle 40.0
#define pDistanceTextFromTitle 10.0
#define pDistanceCatLabelFromText 10.0
#define pDistanceDateLabelsFromCat 8.0
#define pTotalSizeBottomMargin 10.0


@interface EponymViewController (Private)

- (void) adjustDisplayToContent;

@end



@implementation EponymViewController

@synthesize delegate, eponymToBeShown;
@synthesize eponymView, eponymTitleLabel, eponymTextView, eponymCategoriesLabel, dateCreatedLabel, dateUpdatedLabel;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		self.title = @"Eponym";
	}
	return self;
}

- (void) dealloc
{
	[eponymTitleLabel release];					eponymTitleLabel = nil;
	[eponymTextView release];					eponymTextView = nil;
	[eponymCategoriesLabel release];			eponymCategoriesLabel = nil;
	[dateCreatedLabel release];					dateCreatedLabel = nil;
	[dateUpdatedLabel release];					dateUpdatedLabel = nil;
	
	if(eponymView) {
		[eponymView release];					eponymView = nil;
	}
	
	[super dealloc];
}
#pragma mark -



#pragma mark GUI
- (void) loadView
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGFloat fullWidth = screenRect.size.width - 2 * pSideMargin;
	UIColor *transparentColor = [UIColor clearColor];
	
	// The main view
	self.eponymView = [[[UIScrollView alloc] initWithFrame:screenRect] autorelease];
	eponymView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	eponymView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	eponymView.autoresizesSubviews = YES;
	
	self.view = eponymView;
	
	// ****
	// Format the title label
	CGRect titleRect = CGRectMake(pSideMargin, pSideMargin, fullWidth, pHeightTitle);
	self.eponymTitleLabel = [[[UILabel alloc] initWithFrame:titleRect] autorelease];
	eponymTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	eponymTitleLabel.userInteractionEnabled = NO;
	eponymTitleLabel.font = [UIFont boldSystemFontOfSize:28.0];
	eponymTitleLabel.numberOfLines = 1;
	eponymTitleLabel.adjustsFontSizeToFitWidth = YES;
	eponymTitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
	eponymTitleLabel.backgroundColor = transparentColor;
	eponymTitleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
	eponymTitleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	
	[eponymView addSubview:eponymTitleLabel];
	
	// ****
	// Compose the container
	CGRect containerRect = CGRectMake(pSideMargin, pSideMargin + pHeightTitle + pDistanceTextFromTitle, fullWidth, 0.0);
	
	UIView *container = [[[UIView alloc] initWithFrame:containerRect] autorelease];
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	container.autoresizesSubviews = YES;
	
	// Text view
	self.eponymTextView = [[[EponymTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, fullWidth, 0.0)] autorelease];
	eponymTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	eponymTextView.userInteractionEnabled = NO;
	eponymTextView.editable = NO;
	eponymTextView.font = [UIFont systemFontOfSize:18.0];
	
	[container addSubview:eponymTextView];
	
	// Categories Label
	CGFloat labelWidth = fullWidth - 2 * pLabelSideMargin;
	CGRect catRect = CGRectMake(pLabelSideMargin, eponymTextView.bounds.size.height + pDistanceCatLabelFromText, labelWidth, 20.0);
	
	self.eponymCategoriesLabel = [[[UILabel alloc] initWithFrame:catRect] autorelease];
	eponymCategoriesLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	eponymCategoriesLabel.font = [UIFont systemFontOfSize:18.0];
	eponymCategoriesLabel.backgroundColor = transparentColor;
	eponymCategoriesLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
	eponymCategoriesLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	
	[container addSubview:eponymCategoriesLabel];
	
	// Date labels
	CGRect createdRect = CGRectMake(pLabelSideMargin, catRect.origin.y + catRect.size.height + pDistanceDateLabelsFromCat, labelWidth, 15.0);
	self.dateCreatedLabel = [[[UILabel alloc] initWithFrame:createdRect] autorelease];
	dateCreatedLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	dateCreatedLabel.textColor = [UIColor darkGrayColor]; 
	dateCreatedLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	dateCreatedLabel.backgroundColor = transparentColor;
	
	CGRect updatedRect = CGRectMake(pLabelSideMargin, createdRect.origin.y + createdRect.size.height, labelWidth, 15.0);
	self.dateUpdatedLabel = [[[UILabel alloc] initWithFrame:updatedRect] autorelease];
	dateUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	dateUpdatedLabel.textColor = dateCreatedLabel.textColor;
	dateUpdatedLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	dateUpdatedLabel.backgroundColor = transparentColor;
	
	[container addSubview:dateCreatedLabel];
	[container addSubview:dateUpdatedLabel];
	[eponymView addSubview:container];
}

- (void) viewDidLoad
{
	[self adjustDisplayToContent];
}

- (void) viewWillAppear:(BOOL)animated
{
	// title and text
	eponymTitleLabel.text = eponymToBeShown.title;
	eponymTextView.text = eponymToBeShown.text;
	
	// categories
	eponymCategoriesLabel.text = [eponymToBeShown.categories componentsJoinedByString:@", "];
	
	// dates
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	if(eponymToBeShown.created) {
		dateCreatedLabel.hidden = NO;
		dateCreatedLabel.text = [NSString stringWithFormat:@"Created: %@", [dateFormatter stringFromDate:eponymToBeShown.created]];
	}
	else {
		dateCreatedLabel.hidden = YES;
	}
	
	if(eponymToBeShown.lastedit) {
		dateUpdatedLabel.hidden = NO;
		dateUpdatedLabel.text = [NSString stringWithFormat:@"Updated: %@", [dateFormatter stringFromDate:eponymToBeShown.lastedit]];
	}
	else {
		dateUpdatedLabel.hidden = YES;
	}
	
	[self adjustDisplayToContent];
}


- (void) adjustDisplayToContent
{
	// Size needed to fit all text
	CGRect currRect = eponymTextView.bounds;
	CGSize szMax = CGSizeMake(currRect.size.width - 21.0, 100000.0);
	CGSize optimalSize = [eponymToBeShown.text sizeWithFont:eponymTextView.font constrainedToSize:szMax];
	
	CGRect newRect = CGRectMake(0.0, 0.0, currRect.size.width, optimalSize.height + 20.0);
	eponymTextView.frame = newRect;
	
	// Align the labels below
	CGRect catRect = eponymCategoriesLabel.frame;
	catRect.origin.y = newRect.size.height + pDistanceCatLabelFromText;
	eponymCategoriesLabel.frame = catRect;
	
	CGFloat newHeight = catRect.origin.y + catRect.size.height;
	
	if(!dateCreatedLabel.hidden) {
		CGRect creaRect = dateCreatedLabel.frame;
		creaRect.origin.y = newHeight + pDistanceDateLabelsFromCat;
		dateCreatedLabel.frame = creaRect;
		newHeight = creaRect.origin.y + creaRect.size.height;
	}
	
	if(!dateUpdatedLabel.hidden) {
		CGRect updRect = dateUpdatedLabel.frame;
		updRect.origin.y = newHeight;
		dateUpdatedLabel.frame = updRect;
		newHeight = updRect.origin.y + updRect.size.height;
	}
	
	// tell the container view his new height
	newHeight += pTotalSizeBottomMargin;
	CGRect superRect = eponymTextView.superview.frame;
	superRect.size.height = 10000.0;					// using newHeight here gives strange results
	eponymTextView.superview.frame = superRect;
	
	// tell eponymView our size so that scrolling is possible
	newHeight = eponymTextView.superview.frame.origin.y + newHeight;
	CGFloat minHeight = [[UIScreen mainScreen] applicationFrame].size.height;
	CGSize contSize = CGSizeMake(eponymView.contentSize.width, newHeight);
	eponymView.contentSize = contSize;
	
	// scroll to top when needed
	if(newHeight < minHeight) {
		[eponymView scrollRectToVisible:CGRectMake(0.0, 0.0, 10.0, 10.0) animated:NO];
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
	return YES;		//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation
{
	[self adjustDisplayToContent];
}

- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];	// Releases the view if it doesn't have a superview
}


@end
