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


static NSString *MyCellIdentifier = @"EponymCell";


@interface ListViewController (Private)

- (void) abortSearch;
- (void) registerForKeyboardNotifications;
- (void) forgetAboutKeyboardNotifications;
- (void) keyboardDidShow:(NSNotification*)aNotification;
- (void) keyboardWillHide:(NSNotification*)aNotification;

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
	self.eponymArrayCache = nil;
	self.eponymSectionArrayCache = nil;
	self.myTableView = nil;
	self.mySearchBar = nil;
	self.initSearchButton = nil;
	self.abortSearchButton = nil;
	
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
	self.initSearchButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																		   target:self
																		   action:@selector(initSearch)] autorelease];
	self.abortSearchButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self
																			action:@selector(abortSearch)] autorelease];
	self.navigationItem.rightBarButtonItem = initSearchButton;
}

- (void) viewDidLoad
{
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
	if(switchTo) {
		self.navigationItem.rightBarButtonItem = abortSearchButton;
		self.navigationItem.hidesBackButton = YES;
		self.navigationItem.titleView = mySearchBar;
		
		BOOL isSideways = (UIInterfaceOrientationLandscapeLeft == [self interfaceOrientation] || UIInterfaceOrientationLandscapeRight == [self interfaceOrientation]);
		CGFloat barHeight = isSideways ? 32 : 44;
		CGRect searchBarRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, barHeight);
		mySearchBar.bounds = searchBarRect;
//		mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = isSideways ? nil : [delegate naviBarTintColor];
		
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
		
//		mySearchBar.tintColor = self.navigationController.navigationBar.tintColor = [delegate naviBarTintColor];
		
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
	NSIndexPath *selectedCellIndexPath = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:selectedCellIndexPath animated:NO];
	
	[delegate setEponymShown:0];
	
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
	
	[self registerForKeyboardNotifications];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[self forgetAboutKeyboardNotifications];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	// adjust searchbar if necessary
	if(self.navigationItem.titleView == mySearchBar) {
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
		return nil;
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
				selectedCell.image = selectedEponym.starred ? [delegate starImageListActive] : nil;
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
	return keyboardShown ? nil : eponymSectionArrayCache;
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
		return 1;
	}
	return [[eponymArrayCache objectAtIndex:section] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([eponymArrayCache count] < 1) {
		CGFloat tableHeight = tableView.frame.size.height;
		return tableHeight;
	}
	return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// if we have no eponyms, display a hint instead
	if([eponymArrayCache count] < 1) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:nil] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		if(0 == indexPath.row) {
			CGRect cellBounds = [cell bounds];
			cellBounds.size.width -= 40.0;
			cellBounds.origin.x += 20.0;
			cellBounds.size.height = 0.7 * cellBounds.size.height;
			UILabel *label = [[[UILabel alloc] initWithFrame:cellBounds] autorelease];
			
			label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			label.font = [UIFont systemFontOfSize:15.0];
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
		
		BOOL isStarredList = (-1 == [delegate categoryIDShown]);
		Eponym *thisEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		cell.text = [thisEponym title];
		cell.image = (!isStarredList && thisEponym.starred) ? [delegate starImageListActive] : nil;
		thisEponym.eponymCell = cell;
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
#pragma mark -



#pragma mark UIKeyboardNotifications
- (void) registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
}

- (void) forgetAboutKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) keyboardDidShow:(NSNotification*)aNotification
{
	if(keyboardShown)
		return;
	
	NSDictionary* info = [aNotification userInfo];
	NSValue* boundsValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [boundsValue CGRectValue].size;
	
	// Resize the table view view
	CGRect viewFrame = [myTableView frame];
	viewFrame.size.height -= keyboardSize.height;
	myTableView.frame = viewFrame;
	
	keyboardShown = YES;
	[myTableView reloadData];
}


- (void) keyboardWillHide:(NSNotification*)aNotification
{
	NSDictionary* info = [aNotification userInfo];
	NSValue* boundsValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [boundsValue CGRectValue].size;
	
	// adjust table view height to full height again
	CGRect viewFrame = [myTableView frame];
	viewFrame.size.height += keyboardSize.height;
	myTableView.frame = viewFrame;
	
	keyboardShown = NO;
	[myTableView reloadData];
}


@end
