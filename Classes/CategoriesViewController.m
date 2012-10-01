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
#import "AppDelegate.h"
#import "EponymCategory.h"
#import "ListViewController.h"


static NSString *MyCellIdentifier = @"MyIdentifier";


@implementation CategoriesViewController

@synthesize delegate, categoryArrayCache;


- (void)dealloc
{
	self.categoryArrayCache = nil;
	
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"Categories" : @"Eponyms";
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setCategoryShown:nil];
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



#pragma mark - KVC
- (void)setCategoryArrayCache:(NSArray *)categories
{
	if (categories != categoryArrayCache) {
		[categoryArrayCache release];
		categoryArrayCache = [categories retain];
	}
	
	if (categories) {
		[self.tableView reloadData];
	}
}



#pragma mark - UITableView delegate methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EponymCategory *selectedCategory = [[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[delegate loadEponymsOfCategory:selectedCategory containingString:nil animated:YES];
	
	if (delegate.listController != self.navigationController.topViewController) {
		[self.navigationController pushViewController:delegate.listController animated:YES];
	}
}



#pragma mark - UITableView datasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	NSUInteger count = [categoryArrayCache count];
	return (count < 1) ? 1 : count;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView
{
	return [NSArray array];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger) section
{
	return (1 == section) ? @"Categories" : nil;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger) section
{
	return [[categoryArrayCache objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyCellIdentifier] autorelease];
	}
	
	cell.textLabel.text = [[[categoryArrayCache objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] title];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}


@end
