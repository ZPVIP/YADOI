//
//  WordExplain+Create.m
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordExplain+Create.h"
#import "WordEntity.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation WordExplain (Create)
+ (WordExplain *)wordExplainWithString:(NSString *)explainString
                               forWord:(WordEntity *)wordEntity
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (explainString == nil) {
        DDLogVerbose(@"创建条目解释时，给定 string 为空不能创建");
        return nil;
    }
    
    WordExplain *explain = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WordExplain"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(word = %@) AND (explain = %@)", wordEntity, explainString];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"explain" ascending:YES];
    request.predicate = predicate;
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    if (error != nil) {
        DDLogError(@"查询 WordExplain 时出错，%@", error);
        return nil;
    }
    
    if (matches == nil || [matches count] > 1) {
        DDLogError(@"查询 WordExplain 的结果不正常。");
        return nil;
    } else if ([matches count] == 0) {
        explain = [NSEntityDescription insertNewObjectForEntityForName:@"WordExplain" inManagedObjectContext:context];
        explain.explain = explainString;
        explain.word = wordEntity;
        DDLogVerbose(@"%@插入解释项成功", wordEntity.spell);
        
    } else {
        DDLogVerbose(@"%@的该条解释已经存在,未插入", wordEntity.spell);
        explain = [matches lastObject];
    }
    
    return explain;
}
@end
