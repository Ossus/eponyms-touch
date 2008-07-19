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


static NSString *MyCellIdentifier = @"MyIdentifier";


@implementation CategoriesViewController

@synthesize delegate, myTableView, atLaunchScrollTo;
@dynamic categoryArrayCache;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
		self.title = @"Categories";
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
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:delegate action:@selector(showInfoPanel:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	
	self.navigationItem.rightBarButtonItem = infoBarButton;
	[infoBarButton release];
}

- (void) viewWillAppear:(BOOL)animated
{
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	[delegate setCategoryShown:-1];
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
	[categoryArrayCache release];		categoryArrayCache = nil;
	[myTableView release];				myTableView = nil;
	
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
	[categories retain];
	[categoryArrayCache release];
	categoryArrayCache = categories;
	
	[myTableView reloadData];
}



#pragma mark UITableView delegate methods
- (UITableViewCellAccessoryType) tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryDisclosureIndicator;
}

// table selection changed
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger selectedCategory = [[[categoryArrayCache objectAtIndex:indexPath.row] objectForKey:@"id"] intValue];
	[delegate loadEponymsOfCategory:selectedCategory containingString:nil animated:YES];
}
#pragma mark -



#pragma mark UITableView datasource methods
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
	return [categoryArrayCache count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,0,0) reuseIdentifier:MyCellIdentifier] autorelease];
	}
	
	cell.text = [[categoryArrayCache objectAtIndex:indexPath.row] objectForKey:@"title"];
	
	return cell;
}
#pragma mark -


@end
