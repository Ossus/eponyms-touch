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


@interface ListViewController ()

- (void) searchForString:(NSString *)searchString;
- (void) reallySearchForString;
- (void) abortSearch;

@end


@implementation ListViewController

@synthesize delegate, mySearchBar, initSearchButton, abortSearchButton, searchTimeoutTimer;
@synthesize eponymArrayCache, eponymSectionArrayCache;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = @"Eponyms";
	}
	return self;
}

- (void) dealloc
{
	self.eponymArrayCache = nil;
	self.eponymSectionArrayCache = nil;
	self.mySearchBar = nil;
	self.initSearchButton = nil;
	self.abortSearchButton = nil;
	if (searchTimeoutTimer && [searchTimeoutTimer isValid]) {
		[searchTimeoutTimer invalidate];
	}
	self.searchTimeoutTimer = nil;
	
	[super dealloc];
}

// compose the interface
- (void) viewDidLoad
{
	[super viewDidLoad];
	
	// Create the buttons to toggle search
	self.initSearchButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																		   target:self
																		   action:@selector(initSearch)] autorelease];
	self.abortSearchButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self
																			action:@selector(abortSearch)] autorelease];
	self.navigationItem.rightBarButtonItem = initSearchButton;
	
	// Create the search bar
	self.mySearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
//	mySearchBar.tintColor = [delegate naviBarTintColor];
	mySearchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	mySearchBar.delegate = self;
	mySearchBar.showsCancelButton = NO;
	mySearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	mySearchBar.placeholder = @"Search";
	
	//mySearchBar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}
#pragma mark -



#pragma mark GUI
- (void) switchToSearchMode:(BOOL)switchTo
{
	// switch searchmode on
	if (switchTo) {
		self.noDataHint = @"No eponyms match your search criteria";
		
		self.navigationItem.rightBarButtonItem = abortSearchButton;
		self.navigationItem.hidesBackButton = YES;
		self.navigationItem.titleView = mySearchBar;
		isSearching = YES;
		
		BOOL isSideways = (UIInterfaceOrientationLandscapeLeft == [self interfaceOrientation]
						   || UIInterfaceOrientationLandscapeRight == [self interfaceOrientation]);
		CGFloat barHeight = isSideways ? 32 : 44;
		CGRect searchBarRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, barHeight);
		mySearchBar.bounds = searchBarRect;
		mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = isSideways ? nil : [delegate naviBarTintColor];
		
		[mySearchBar becomeFirstResponder];
	}
	
	// switch off
	else {
		self.noDataHint = [(EponymCategory *)[delegate categoryShown] hint];
		
		if (searchTimeoutTimer && [searchTimeoutTimer isValid]) {
			[searchTimeoutTimer invalidate];
		}
		if (![mySearchBar isFirstResponder]) {
			[delegate loadEponymsOfCurrentCategoryContainingString:nil animated:NO];
		}
		else {
			mySearchBar.text = @"";
			[mySearchBar resignFirstResponder];
		}
		
		mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = [delegate naviBarTintColor];
		
		self.navigationItem.rightBarButtonItem = initSearchButton;
		self.navigationItem.hidesBackButton = NO;
		self.navigationItem.titleView = nil;
		isSearching = NO;
	}
}

- (void) initSearch
{
	[self switchToSearchMode:YES];
}

- (void) searchForString:(NSString *)searchText
{
	if (searchTimeoutTimer && [searchTimeoutTimer isValid]) {
		[searchTimeoutTimer invalidate];
	}
	
	self.searchTimeoutTimer = [NSTimer timerWithTimeInterval:0.3
													  target:self
													selector:@selector(reallySearchForString)
													userInfo:searchText
													 repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:searchTimeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void) reallySearchForString
{
	if (searchTimeoutTimer) {
		NSString *searchText = [searchTimeoutTimer userInfo];
		[delegate loadEponymsOfCurrentCategoryContainingString:searchText animated:NO];
	}
}

- (void) abortSearch
{
	[self switchToSearchMode:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// deselect the previously shown eponym
	NSIndexPath *selectedCellIndexPath = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:selectedCellIndexPath animated:NO];
	
	[delegate setEponymShown:0];
	
	// set the Title and the back button title
	if (delegate) {
		self.title = [[delegate categoryShown] title];
		self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:[[delegate categoryShown] tag] style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate) {
		return YES;
	}
	
	return IS_PORTRAIT(toInterfaceOrientation);
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	// adjust searchbar if necessary
	if (self.navigationItem.titleView == mySearchBar) {
		BOOL wasSideways = (UIInterfaceOrientationLandscapeLeft == fromInterfaceOrientation || UIInterfaceOrientationLandscapeRight == fromInterfaceOrientation);
		
		CGRect searchBarRect = mySearchBar.bounds;
		searchBarRect.size.height = wasSideways ? 44 : 32;
		mySearchBar.bounds = searchBarRect;
		
		// workaround to the tintColoring bug (bad color alignment) -> un-tint the bar!
//		mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = wasSideways ? [delegate naviBarTintColor] : nil;
	}
}
#pragma mark -



#pragma mark Data Cache
- (void) cacheEponyms:(NSArray *)eponyms andHeaders:(NSArray *)sections
{
	self.eponymArrayCache = eponyms;
	self.eponymSectionArrayCache = sections	;
	
	if (eponyms) {
		[self.tableView reloadData];
		
		if ([eponymArrayCache count] > 0) {
			[self hideNoDataHintAnimated:NO];
		}
		else {
			[self showNoDataHintAnimated:NO];
		}
	}
}
#pragma mark -



#pragma mark UITableView delegate methods
- (NSIndexPath *) tableView:(UITableView *)aTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([eponymArrayCache count] < 1) {
		return nil;
	}
	return indexPath;
}

- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([eponymArrayCache count] > 0) {
		if (isSearching) {
			[mySearchBar resignFirstResponder];
		}
		
		Eponym *selectedEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		[delegate loadEponym:selectedEponym animated:YES];
	}
}

// our own new delegate method in case of a double tap
- (void) tableView:(TouchTableView *)aTableView didDoubleTapRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([eponymArrayCache count] > 0) {
		Eponym *selectedEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		if (selectedEponym) {
			[selectedEponym toggleStarred];
			
			// show/hide the star
			UITableViewCell *selectedCell = [aTableView cellForRowAtIndexPath:indexPath];
			if (selectedCell) {
				selectedCell.imageView.image = selectedEponym.starred ? [delegate starImageListActive] : nil;
			}
		}
	}
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)aTableView
{
	return [eponymArrayCache count];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)aTableView
{
	return eponymSectionArrayCache;
}

/*- (UIView *) tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
}*/

- (NSString *) tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
	if ([eponymArrayCache count] > section) {
		return [eponymSectionArrayCache objectAtIndex:section];
	}
	return nil;
}


// eponyms per section
- (NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return [[eponymArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *MyCellIdentifier = @"EponymCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:MyCellIdentifier] autorelease];
	}
	
	BOOL isStarredList = (-1 == [delegate categoryIDShown]);
	Eponym *thisEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = [thisEponym title];
	cell.imageView.image = (!isStarredList && thisEponym.starred) ? [delegate starImageListActive] : nil;
	
	thisEponym.eponymCell = cell;
	
	return cell;
}
#pragma mark -



#pragma mark UISearchBar delegate methods
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

// we want live search so we do our searching here, not in the searchBarTextDidEndEditing delegate method
- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self searchForString:searchText];
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
