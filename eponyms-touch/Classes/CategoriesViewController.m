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

@synthesize delegate;
@dynamic categoryArrayCache;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = @"Eponyms";
	}
	return self;
}

// set up the table
- (void) viewDidLoad
{
	[super viewDidLoad];
	
	// add the info panel button
	[self showNewEponymsAvailable:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setCategoryShown:nil];
	[delegate setEponymShown:0];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (((eponyms_touchAppDelegate *)[[UIApplication sharedApplication] delegate]).allowAutoRotate) {
		return YES;
	}
	
	return IS_PORTRAIT(toInterfaceOrientation);
}


- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}


- (void) dealloc
{
	self.categoryArrayCache = nil;
	
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
	if (categories != categoryArrayCache) {
		[categoryArrayCache release];
		categoryArrayCache = [categories retain];
	}
	
	if (categories) {
		[self.tableView reloadData];
	}
}
#pragma mark -



#pragma mark GUI
- (void) showNewEponymsAvailable:(BOOL)hasNew
{
	UIButton *infoButton;
	CGRect buttonSize = CGRectMake(0.0, 0.0, 30.0, 30.0);
	
	if (hasNew) {
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

// table selection changed
- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EponymCategory *selectedCategory = [[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[delegate loadEponymsOfCategory:selectedCategory containingString:nil animated:YES];
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)aTableView
{
	NSUInteger count = [categoryArrayCache count];
	return (count < 1) ? 1 : count;
}
- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)aTableView
{
	return [NSArray array];
}

/*- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger) section
 {
 }*/
- (NSString *) tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger) section
{
	return (1 == section) ? @"Categories" : nil;
}

- (NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger) section
{
	return [[categoryArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:MyCellIdentifier] autorelease];
	}
	
	cell.textLabel.text = [[[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] title];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}
#pragma mark -


@end
