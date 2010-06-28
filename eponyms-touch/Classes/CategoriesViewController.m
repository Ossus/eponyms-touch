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
		self.title = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"Categories" : @"Eponyms";
	}
	return self;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setCategoryShown:nil];
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
