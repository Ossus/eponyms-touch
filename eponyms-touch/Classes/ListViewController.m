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
#import "Eponym.h"


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
	self.myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
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
			[delegate loadEponymsOfCategory:[delegate categoryShown] containingString:nil animated:NO];
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
	
	// adjust the searchBar to the reotation (if necessary)
	if(mySearchBar == self.navigationItem.titleView) {
		CGFloat barHeight = self.navigationItem.titleView.superview.bounds.size.height;
		CGRect searchBarRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, barHeight);
		mySearchBar.bounds = searchBarRect;
	}
	
	// set the Title
	if(delegate) {
		self.title = [delegate shownCategoryTitle];
	}
	
	// remembers scroll position across restarts
	if(atLaunchScrollTo > 0.0) {
		CGRect rct = [myTableView bounds];
		rct.origin.y = atLaunchScrollTo;
		[myTableView setBounds:rct];
		atLaunchScrollTo = 0.0;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
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
	
	// !! reload section headers somehow!
	//[self didChangeValueForKey:@"eponymSectionArrayCache"];		// does not work
	[myTableView reloadData];
}
#pragma mark -



#pragma mark UITableView delegate methods
- (UITableViewCellAccessoryType) tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryNone;
}

// table selection changed
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Eponym *selectedEponym = [[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[delegate loadEponym:selectedEponym animated:YES];
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return [eponymArrayCache count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return eponymSectionArrayCache;
}

/*- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger) section
{
}*/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger) section
{
	return [eponymSectionArrayCache objectAtIndex:section];
}


// eponyms per section
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
	return [[eponymArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = MyCellIdentifier;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:identifier] autorelease];
	}
	
	cell.text = [[[eponymArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] title];
	
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
	[delegate loadEponymsOfCategory:[delegate categoryShown] containingString:searchText animated:NO];
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
