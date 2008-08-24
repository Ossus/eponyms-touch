//
//  ListViewController.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the eponym list view for eponyms-touch
//  


#import "ListViewController.h"
#import "eponyms_touchAppDelegate.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "TouchTableView.h"

#define DISPLAY_HINT_IN_CELL 2			// if we have no eponyms to display, show a hint in this table cell (starting at ZERO)


static NSString *MyCellIdentifier = @"EponymCell";


@interface ListViewController (Private)
- (void) abortSearch;
@end


@implementation ListViewController

@synthesize delegate, myTableView, mySearchBar, initSearchButton, abortSearchButton, atLaunchScrollTo;
@synthesize eponymArrayCache, eponymSectionArrayCache;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		self.title = @"Eponyms";
	}
	return self;
}

- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];		// Releases the view if it doesn't have a superview
}


- (void) dealloc
{
	[eponymArrayCache release];				eponymArrayCache = nil;
	[eponymSectionArrayCache release];		eponymSectionArrayCache = nil;
	[myTableView release];					myTableView = nil;
	[mySearchBar release];					mySearchBar = nil;
	[initSearchButton release];				initSearchButton = nil;
	[abortSearchButton release];			abortSearchButton = nil;
	
	[super dealloc];
}

// compose the interface
- (void) loadView
{
	// Create the table
	self.myTableView = [[TouchTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	myTableView.autoresizesSubviews = YES;
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.sectionIndexMinimumDisplayRowCount = 20;
	
	self.view = myTableView;
	
	// Create the buttons to toggle search
	initSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(initSearch)];
	abortSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(abortSearch)];
	self.navigationItem.rightBarButtonItem = initSearchButton;
}

- (void) viewDidLoad
{
	// Create the search bar
	self.mySearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
	//	mySearchBar.tintColor = [[UIColor alloc] initWithRed:0.75 green:0.80 blue:0.80 alpha:1.0];
	mySearchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	mySearchBar.delegate = self;
	mySearchBar.showsCancelButton = NO;
	mySearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	mySearchBar.placeholder = @"Search";
}
#pragma mark -



#pragma mark GUI
- (void) switchToSearchMode:(BOOL)switchTo
{
	// switch searchmode on
	if(switchTo) {
		self.navigationItem.rightBarButtonItem = abortSearchButton;
		self.navigationItem.hidesBackButton = YES;
		self.navigationItem.titleView = mySearchBar;
		
		CGFloat barHeight = self.navigationItem.titleView.superview.bounds.size.height;
		CGRect searchBarRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, barHeight);
		mySearchBar.bounds = searchBarRect;
		
		[mySearchBar becomeFirstResponder];
	}
	
	// switch off
	else {
		if(![mySearchBar isFirstResponder]) {
			[delegate loadEponymsOfCurrentCategoryContainingString:nil animated:NO];
		}
		else {
			mySearchBar.text = @"";
			[mySearchBar resignFirstResponder];
		}
		
		self.navigationItem.rightBarButtonItem = initSearchButton;
		self.navigationItem.hidesBackButton = NO;
		self.navigationItem.titleView = nil;
	}
}

- (void) initSearch
{
	[self switchToSearchMode:YES];
}

- (void) abortSearch
{
	[self switchToSearchMode:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	// deselect the previously shown eponym
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setEponymShown:0];
	
	// adjust the searchBar to the rotation (if necessary)
	if(mySearchBar == self.navigationItem.titleView) {
		// The following does not really work. Any other way to determine the navigationItem's height?
		//CGFloat barHeight = self.navigationItem.titleView.superview.bounds.size.height;
		// temporary method:
		UIInterfaceOrientation orientation = [self interfaceOrientation];
		CGFloat barHeight = (UIInterfaceOrientationPortrait == orientation || UIInterfaceOrientationPortraitUpsideDown == orientation) ? 44 : 32;
		
		CGRect searchBarRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, barHeight);
		mySearchBar.bounds = searchBarRect;
	}
	
	// set the Title and the back button title
	if(delegate) {
		self.title = [[delegate categoryShown] title];
		self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:[[delegate categoryShown] tag] style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
	}
	
	// remembers scroll position across restarts
	if(atLaunchScrollTo > 0.0) {
		CGRect rct = [myTableView bounds];
		rct.origin.y = atLaunchScrollTo;
		[myTableView setBounds:rct];
		atLaunchScrollTo = 0.0;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation
{
	//self.view.frame = [[UIScreen mainScreen] applicationFrame];
}
#pragma mark -



#pragma mark Data Cache
- (void) cacheEponyms:(NSArray *)eponyms andHeaders:(NSArray *)sections
{
	self.eponymArrayCache = eponyms;
	self.eponymSectionArrayCache = sections	;
	
	if(eponyms) {
		[myTableView reloadData];
	}
}
#pragma mark -



#pragma mark UITableView delegate methods
- (UITableViewCellAccessoryType) tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryNone;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([eponymArrayCache count] < 1) {
		return [NSIndexPath indexPathWithIndexes:0 length:0];
	}
	return indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([eponymArrayCache count] > 0) {
		Eponym *selectedEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		[delegate loadEponym:selectedEponym animated:YES];
	}
}

// our own new delegate method in case of a double tap
- (void) tableView:(TouchTableView *)tableView didDoubleTapRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([eponymArrayCache count] > 0) {
		Eponym *selectedEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		if(selectedEponym) {
			[selectedEponym toggleStarred];
			
			// show/hide the star
			UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
			if(selectedCell) {
				selectedCell.image = selectedEponym.starred ? [delegate starImage] : nil;
			}
		}
	}
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	NSUInteger count = [eponymArrayCache count];
	return (count < 1) ? 1 : count;
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return eponymSectionArrayCache;
}

/*- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger) section
{
}*/

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger) section
{
	if([eponymArrayCache count] > section) {
		return [eponymSectionArrayCache objectAtIndex:section];
	}
	return nil;
}


// eponyms per section
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
	// if we have no eponyms, display a hint instead
	if([eponymArrayCache count] < 1) {
		return DISPLAY_HINT_IN_CELL + 1;
	}
	return [[eponymArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// if we have no eponyms, display a hint instead
	if([eponymArrayCache count] < 1) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:nil] autorelease];
		
		if(indexPath.row == DISPLAY_HINT_IN_CELL) {
			UILabel *label = [[[UILabel alloc] initWithFrame:[cell bounds]] autorelease];
			
			label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			label.textAlignment = UITextAlignmentCenter;
			label.textColor = [UIColor grayColor];
			label.lineBreakMode = UILineBreakModeWordWrap;
			label.text = [(EponymCategory *)[delegate categoryShown] hint];
			
			[cell.contentView addSubview:label];
		}
		else if([cell.contentView subviews]) {
			[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		}
	}
	
	// ordinary eponym cell
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
		if(cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:MyCellIdentifier] autorelease];
		}
		
		Eponym *thisEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		cell.text = [thisEponym title];
		cell.image = thisEponym.starred ? [delegate starImage] : nil;
	}
	
	return cell;
}
#pragma mark -



#pragma mark UISearchBar delegate methods
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	if(![searchBar.text isEqualToString:@""]) {
		[delegate loadEponymsOfCurrentCategoryContainingString:searchBar.text animated:NO];
	}
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

// we want live search so we do our searching here, not in the searchBarTextDidEndEditing delegate method
- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[delegate loadEponymsOfCurrentCategoryContainingString:searchText animated:NO];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[mySearchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self abortSearch];
}


@end
