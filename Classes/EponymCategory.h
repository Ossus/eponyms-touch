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

#import <Foundation/Foundation.h>


@interface EponymCategory : NSObject

@property (nonatomic, assign) NSInteger myID;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *hint;
@property (nonatomic, strong) NSString *sqlWhereStatement;
@property (nonatomic, strong) NSString *sqlOrderStatement;
@property (nonatomic, assign) NSInteger sqlLimitTo;

- (id)initWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;
+ (id)eponymCategoryWithID:(NSInteger)thisID tag:(NSString *)myTag title:(NSString *)myTitle whereStatement:(NSString *)myStatement;


@end
