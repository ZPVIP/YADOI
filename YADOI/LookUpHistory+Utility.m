//
//  LookUpHistory+Utility.m
//  YADOI
//
//  Created by HaiLee on 12-11-8.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "LookUpHistory+Utility.h"
#import "WordEntity+Utility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation LookUpHistory (Utility)

- (NSString *)addDateString
{
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
    }
    
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self.onDate];
}

+ (LookUpHistory *)lookUpHistoryWithThisWord:(WordEntity *)wordEntity
{
    LookUpHistory *lookUpHistory = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LookUpHistory"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"word == %@", wordEntity];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"onDate" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [wordEntity.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error != nil) {
        DDLogError(@"查询LookUpHistory时出错:%@,%@", [error localizedDescription], [error localizedFailureReason]);
        return nil;
    }

    if ([matches count] == 1) {
        lookUpHistory = [matches lastObject];
    } else {
        lookUpHistory = nil;
    }
    
    return lookUpHistory;
}

+ (BOOL)isThisWordInLookUpHistory:(WordEntity *)wordEntity
{
    // 如果能查到就是在，如果查不到就是不在
    return ([LookUpHistory lookUpHistoryWithThisWord:wordEntity] != nil);
}

+ (void)addWordToLookUpHistory:(WordEntity *)wordEntity
{
    // 如果已经在历史记录中则更新其日期，否则新加一个
    LookUpHistory *lookUpHistory = nil;
    if ([LookUpHistory isThisWordInLookUpHistory:wordEntity]) {
        lookUpHistory = [LookUpHistory lookUpHistoryWithThisWord:wordEntity];
    } else {
        lookUpHistory = [NSEntityDescription insertNewObjectForEntityForName:@"LookUpHistory"
                                                      inManagedObjectContext:wordEntity.managedObjectContext];
        lookUpHistory.word = wordEntity;
        lookUpHistory.count = [NSNumber numberWithInt:0];
    }
    
    lookUpHistory.onDate = [NSDate date];
    int temp = lookUpHistory.count.intValue;
    temp += 1;
    lookUpHistory.count = [NSNumber numberWithInt:temp];
    [LookUpHistory saveContext:wordEntity.managedObjectContext];
}

+ (void)deleteLookUpHistory:(LookUpHistory *)lookUpHistory
{
    // 为记录日志用
    NSString *wordSpell = lookUpHistory.word.spell;
    NSManagedObjectContext *context = lookUpHistory.managedObjectContext;
    [context deleteObject:lookUpHistory];
    DDLogVerbose(@"从历史记录中删除%@", wordSpell);
    [LookUpHistory saveContext:context];
}

+ (BOOL)saveContext:(NSManagedObjectContext *)managedObjectContext
{
    NSError *error = nil;
    if (![managedObjectContext save:&error] || error != nil) {
        DDLogError(@"保存context出错 %@, %@", [error localizedDescription], [error localizedFailureReason]);
        return NO;
    }
    return YES;
}
@end
