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
#import "AppDelegate.h"
#import "EponymViewController.h"
#import "EponymCategory.h"
#import "Eponym.h"
#import "TouchTableView.h"


@interface ListViewController ()

- (void)searchForString:(NSString *)searchString;
- (void)reallySearchForString;
- (void)initSearch:(id)sender;
- (void)abortSearch:(id)sender;

@end


@implementation ListViewController


- (void)dealloc
{
	if ([_searchTimeoutTimer isValid]) {
		[_searchTimeoutTimer invalidate];
	}
	
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = @"Eponyms";
	}
	return self;
}

// compose the interface
- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.sectionIndexMinimumDisplayRowCount = 20;
	
	// Create the buttons to toggle search
	self.initSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																		   target:self
																		   action:@selector(initSearch:)];
	self.abortSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self
																			action:@selector(abortSearch:)];
	self.navigationItem.rightBarButtonItem = _initSearchButton;
	
	// Create the search bar
	self.mySearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
//	mySearchBar.tintColor = [delegate naviBarTintColor];
	_mySearchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_mySearchBar.delegate = self;
	_mySearchBar.showsCancelButton = NO;
	_mySearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	_mySearchBar.placeholder = @"Search";
	
	//mySearchBar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		APP_DELEGATE.eponymShown = 0;
	}
	
	// deselect the previously shown eponym
	NSIndexPath *selectedCellIndexPath = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:selectedCellIndexPath animated:NO];
	
	// set the Title and the back button title
	if (_delegate) {
		self.title = [[_delegate categoryShown] title];
		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[[_delegate categoryShown] tag] style:UIBarButtonItemStylePlain target:nil action:nil];
	}
}



#pragma mark - Search
- (void)initSearch:(id)sender
{
	self.noDataHint = @"No eponyms match your search criteria";
	[self.tableView scrollRectToVisible:CGRectMake(0.f, 0.f, 10.f, 10.f) animated:NO];
	
	self.navigationItem.rightBarButtonItem = _abortSearchButton;
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.titleView = _mySearchBar;
	isSearching = YES;
	
	BOOL isSideways = IS_LANDSCAPE([self interfaceOrientation]);
	CGFloat barHeight = isSideways ? 32.f : 44.f;
	CGRect searchBarRect = CGRectMake(0.f, 0.f, self.view.bounds.size.width, barHeight);
	_mySearchBar.bounds = searchBarRect;
	_mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = isSideways ? nil : [_delegate naviBarTintColor];
	
	[_mySearchBar becomeFirstResponder];
}

- (void)abortSearch:(id)sender
{
	self.noDataHint = [(EponymCategory *)[_delegate categoryShown] hint];
	
	if ([_searchTimeoutTimer isValid]) {
		[_searchTimeoutTimer invalidate];
	}
	
	_mySearchBar.text = @"";
	_mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = [_delegate naviBarTintColor];
	
	if ([_mySearchBar isFirstResponder]) {
		[_mySearchBar resignFirstResponder];
	}
	[_delegate loadEponymsOfCurrentCategoryContainingString:nil animated:NO];
	
	self.navigationItem.rightBarButtonItem = _initSearchButton;
	self.navigationItem.hidesBackButton = NO;
	self.navigationItem.titleView = nil;
	isSearching = NO;
	
	[self assureEponymSelectedInListAnimated:NO];
}

- (void)searchForString:(NSString *)searchText
{
	if ([_searchTimeoutTimer isValid]) {
		[_searchTimeoutTimer invalidate];
	}
	
	self.searchTimeoutTimer = [NSTimer timerWithTimeInterval:0.3
													  target:self
													selector:@selector(reallySearchForString)
													userInfo:searchText
													 repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:_searchTimeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void)reallySearchForString
{
	if (_searchTimeoutTimer) {
		NSString *searchText = [_searchTimeoutTimer userInfo];
		[_delegate loadEponymsOfCurrentCategoryContainingString:searchText animated:NO];
	}
}



#pragma mark - Rotation
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



#pragma mark - Selecting and Starring
- (void)assureEponymSelectedInListAnimated:(BOOL)animated
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSUInteger activeEponym = [_delegate eponymShown];
		if (activeEponym > 0) {
			NSUInteger section = 0;
			for (NSArray *catArray in _eponymArrayCache) {
				NSUInteger row = 0;
				for (Eponym *epo in catArray) {
					if (epo.eponym_id == activeEponym) {
						NSIndexPath *myIndex = [NSIndexPath indexPathForRow:row inSection:section];
						if (![self tableView:self.tableView rowIsVisible:myIndex]) {
							[self.tableView selectRowAtIndexPath:myIndex animated:animated scrollPosition:UITableViewScrollPositionTop];
						}
						else {
							[self.tableView selectRowAtIndexPath:myIndex animated:animated scrollPosition:UITableViewScrollPositionNone];
						}
						
						return;
					}
					row++;
				}
				section++;
			}
		}
		
		// no selected eponym - select the first visible one
		else if ([_eponymArrayCache count] > 0) {
			NSArray *visRows = [self.tableView indexPathsForVisibleRows];
			if ([visRows count] > 0) {
				NSIndexPath *firstRow = [visRows objectAtIndex:0];
				
				if ([_eponymArrayCache count] > firstRow.section) {
					if ([[_eponymArrayCache objectAtIndex:firstRow.section] count] > firstRow.row) {
						Eponym *firstEponym = [[_eponymArrayCache objectAtIndex:firstRow.section] objectAtIndex:firstRow.row];
						[_delegate loadEponym:firstEponym animated:NO];
						
						[self.tableView selectRowAtIndexPath:firstRow animated:NO scrollPosition:UITableViewScrollPositionNone];
						return;
					}
				}
			}
			else if ([[_eponymArrayCache objectAtIndex:0] count] > 0) {
				Eponym *firstEponym = [[_eponymArrayCache objectAtIndex:0] objectAtIndex:0];
				[_delegate loadEponym:firstEponym animated:NO];
				
				NSIndexPath *firstIndex = [NSIndexPath indexPathForRow:0 inSection:0];
				[self.tableView selectRowAtIndexPath:firstIndex animated:NO scrollPosition:UITableViewScrollPositionTop];
			}
		}
	}
}

- (void)assureSelectedEponymStarredInList
{
	[self assureEponymAtIndexPathStarredInList:[self.tableView indexPathForSelectedRow]];
}

- (void)assureEponymAtIndexPathStarredInList:(NSIndexPath *)indexPath
{
	if (indexPath) {
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self assureEponymSelectedInListAnimated:YES];
	}
}



#pragma mark - Data Cache
- (void)cacheEponyms:(NSArray *)eponyms andHeaders:(NSArray *)sections
{
	self.eponymArrayCache = eponyms;
	self.eponymSectionArrayCache = sections	;
	
	if (eponyms) {
		[self.tableView reloadData];
		
		if ([_eponymArrayCache count] > 0) {
			[self hideNoDataHintAnimated:NO];
		}
		else {
			[self showNoDataHintAnimated:NO];
		}
	}
}



#pragma mark - UITableView delegate methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([_eponymArrayCache count] > 0) {
		if (isSearching) {
			[_mySearchBar resignFirstResponder];
		}
		
		Eponym *selectedEponym = [[_eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		[_delegate loadEponym:selectedEponym animated:YES];
	}
}

// our own new delegate method in case of a double tap
- (void)tableView:(TouchTableView *)aTableView didDoubleTapRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([_eponymArrayCache count] > 0) {
		Eponym *selectedEponym = [[_eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		if (selectedEponym) {
			[selectedEponym toggleStarred];
			
			// show/hide the star
			[self assureEponymAtIndexPathStarredInList:indexPath];
			[[_delegate eponymController] indicateEponymStarredStatus];
		}
	}
}



#pragma mark - UITableView datasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return [_eponymArrayCache count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView
{
	return _eponymSectionArrayCache;
}

/*- (UIView *) tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
}*/

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
	if ([_eponymArrayCache count] > section) {
		return [_eponymSectionArrayCache objectAtIndex:section];
	}
	return nil;
}


// eponyms per section
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return [[_eponymArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *MyCellIdentifier = @"EponymCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyCellIdentifier];
	}
	
	BOOL isStarredList = (-1 == [_delegate categoryIDShown]);
	Eponym *thisEponym = [[_eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = [thisEponym title];
	cell.imageView.image = (!isStarredList && thisEponym.starred) ? [_delegate starImageListActive] : nil;
	
	return cell;
}



#pragma mark - UISearchBar delegate methods
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

// we want live search so we do our searching here, not in the searchBarTextDidEndEditing delegate method
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self searchForString:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[_mySearchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self abortSearch:nil];
}


@end
