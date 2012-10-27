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


- (id)initWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;
{
	if ((self = [super init])) {
		self.myID = thisID;
		self.tag = myTag;
		self.title = myTitle;
		self.sqlWhereStatement = myStatement;
		
		self.hint = [NSString string];
		self.sqlLimitTo = -1;
	}
	
	return self;
}


+ (id)eponymCategoryWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;
{
	return [[EponymCategory alloc] initWithID:thisID tag:myTag title:myTitle whereStatement:myStatement];
}



#pragma mark - KVC
- (NSString *)_title
{
	if (![_title length] > 0) {
		if ([_tag length] > 0) {
			return _tag;
		}
		return @"(unknown)";
	}
	return _title;
}

- (NSString *)hint
{
	return ([_hint length] > 0) ? _hint : @"No eponyms for this category";
}

- (NSString *)sqlWhereStatement
{
	return _sqlWhereStatement ? _sqlWhereStatement : @"1";
}


- (NSString *)sqlOrderStatement
{
	return _sqlOrderStatement ? _sqlOrderStatement : @"eponym_en";
}


@end
