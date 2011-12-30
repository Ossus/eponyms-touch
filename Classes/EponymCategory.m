//
//  EponymCategory.h
//  eponyms-touch
//
//  Created by Pascal Pfiffner on 23.08.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Eponym Category class
// 

#import "EponymCategory.h"


@implementation EponymCategory

@synthesize myID, tag, sqlLimitTo;
@dynamic title, hint, sqlWhereStatement, sqlOrderStatement;

- (id) initWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;
{
	self = [super init];
	if (self) {
		self.myID = thisID;
		self.tag = myTag;
		self.title = myTitle;
		self.sqlWhereStatement = myStatement;
		
		self.hint = [NSString string];
		self.sqlLimitTo = -1;
	}
	
	return self;
}

- (void) dealloc
{
	self.tag = nil;
	self.title = nil;
	self.hint = nil;
	
	self.sqlWhereStatement = nil;
	self.sqlOrderStatement = nil;
	
	[super dealloc];
}


+ (id) eponymCategoryWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;
{
	return [[[EponymCategory alloc] initWithID:thisID tag:myTag title:myTitle whereStatement:myStatement] autorelease];
}
#pragma mark -



#pragma mark KVC
- (NSString *) title
{
	return [title isEqualToString:@""] ? ([tag isEqualToString:@""] ? @"(unknown)" : tag) : title;
}
- (void) setTitle:(NSString *)newTitle
{
	if (newTitle != title) {
		[title release];
		title = [newTitle retain];
	}
}

- (NSString *) hint
{
	return [hint isEqualToString:@""] ? @"No eponyms for this category" : hint;
}
- (void) setHint:(NSString *)newHint
{
	if (newHint != hint) {
		[hint release];
		hint = [newHint retain];
	}
}

- (NSString *) sqlWhereStatement
{
	return sqlWhereStatement ? sqlWhereStatement : @"1";
}
- (void) setSqlWhereStatement:(NSString *)stmt
{
	if (stmt != sqlWhereStatement) {
		[sqlWhereStatement release];
		sqlWhereStatement = [stmt retain];
	}
}

- (NSString *) sqlOrderStatement
{
	return sqlOrderStatement ? sqlOrderStatement : @"eponym_en";
}
- (void) setSqlOrderStatement:(NSString *)stmt
{
	if (stmt != sqlOrderStatement) {
		[sqlOrderStatement release];
		sqlOrderStatement = [stmt retain];
	}
}



@end
