//
//  CategoriesViewController.m
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 02.07.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  View controller of the categories view for eponyms-touch
//  


#import "CategoriesViewController.h"
#import "eponyms_touchAppDelegate.h"
#import "EponymCategory.h"


static NSString *MyCellIdentifier = @"MyIdentifier";


@implementation CategoriesViewController

@synthesize delegate, myTableView, atLaunchScrollTo;
@dynamic categoryArrayCache;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		self.title = @"Eponyms";
	}
	return self;
}

// set up the table
- (void)loadView
{
	self.myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];	
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	myTableView.autoresizesSubviews = YES;
	self.view = myTableView;
	
	// add the info panel button
	[self showNewEponymsAvailable:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setCategoryShown:nil];
	[delegate setEponymShown:0];
	
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


- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}


- (void) dealloc
{
	self.categoryArrayCache = nil;
	self.myTableView = nil;
	
	[super dealloc];
}
#pragma mark -



#pragma mark KVC
- (NSArray *) categoryArrayCache
{
	return categoryArrayCache;
}
- (void) setCategoryArrayCache:(NSArray *)categories
{
	if(categories != categoryArrayCache) {
		[categoryArrayCache release];
		categoryArrayCache = [categories retain];
	}
	
	if(categories) {
		[myTableView reloadData];
	}
}
#pragma mark -



#pragma mark GUI
- (void) showNewEponymsAvailable:(BOOL)hasNew
{
	UIButton *infoButton;
	CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
	
	if(hasNew) {
		infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[infoButton setImage:[UIImage imageNamed:@"Badge_new_eponyms.png"] forState:(UIControlStateNormal & UIControlStateHighlighted & UIControlStateDisabled & UIControlStateSelected & UIControlStateApplication & UIControlStateReserved)];
		infoButton.showsTouchWhenHighlighted = YES;
		infoButton.frame = buttonSize;
	}
	
	else {
		infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
		infoButton.frame = buttonSize;
	}
	
	// compose and add to navigation bar
	[infoButton addTarget:delegate action:@selector(showInfoPanel:) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	self.navigationItem.rightBarButtonItem = infoBarButton;
	[infoBarButton release];
}
#pragma mark -



#pragma mark UITableView delegate methods
- (UITableViewCellAccessoryType) tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryDisclosureIndicator;
}

// table selection changed
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EponymCategory *selectedCategory = [[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[delegate loadEponymsOfCategory:selectedCategory containingString:nil animated:YES];
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	NSUInteger count = [categoryArrayCache count];
	return (count < 1) ? 1 : count;
}
- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return [NSArray array];
}

/*- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger) section
 {
 }*/
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger) section
{
	return (1 == section) ? @"Categories" : nil;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
	return [[categoryArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:MyCellIdentifier] autorelease];
	}
	
	cell.text = [[[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] title];
	//if(0 == indexPath.section && 1 == indexPath.row) {
	//	cell.image = [delegate starImageListActive];
	//}
	
	return cell;
}
#pragma mark -


@end
