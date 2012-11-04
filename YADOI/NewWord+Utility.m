//
//  NewWord+Utility.m
//  YADOI
//
//  Created by HaiLee on 12-11-2.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "NewWord+Utility.h"
#import "WordEntity.h"
#import "SettingsKey.h"
#import "DDLog.h"

const static int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation NewWord (Utility)
+ (NSArray *)todaysReviewWordsWithContext:(NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil) {
        DDLogError(@"传入的managedObjectContext为空");
        return nil;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewWord"];
    // 过滤条件是:明天之前需要复习的单词
    NSCalendar *gregorianClander = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned dateUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *tomorrowDateComponents = [gregorianClander components:dateUnits fromDate:[NSDate date]];
    tomorrowDateComponents.day += 1;
    NSDate *tomorrow = [gregorianClander dateFromComponents:tomorrowDateComponents];
    request.predicate = [NSPredicate predicateWithFormat:@"nextReviewDate < %@", tomorrow];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nextReviewDate" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DDLogError(@"执行 request 时出错,%@,错误信息：%@, %@", request, [error localizedDescription], [error localizedFailureReason]);
        return nil;
    }
    
    int dailyReviewWordNumber = [[NSUserDefaults standardUserDefaults] integerForKey:DAILY_REVIEW_WORD_NUMBER];
    if ([matches count] <= dailyReviewWordNumber) {
        return matches;
    } else {
        return [matches subarrayWithRange:NSMakeRange(0, dailyReviewWordNumber)];
    }
}
+ (NSInteger)countOfNewWordWithConext:(NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil) {
        DDLogError(@"传入的managedObjectContext为空");
        return 0;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewWord"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nextReviewDate" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DDLogError(@"执行 request 时出错,%@,错误信息：%@, %@", request, [error localizedDescription], [error localizedFailureReason]);
        return 0;
    }
    
    DDLogVerbose(@"生词本中单词总数是 %d", [matches count]);
    return [matches count];
}

// 取得某个 Level 对应的下次复习的时间间隔
+ (NSInteger)dayIntervalToNextReview:(NSNumber *)level
{
    int currentLevel = level.intValue;
    if (currentLevel <= 2) {
        return 1;
    } else if (currentLevel <= 4) {
        return 2;
    } else if (currentLevel <= 6) {
        return 4;
    } else if (currentLevel <= 9) {
        return 7;
    } else {
        return 15;
    }
}

- (void)updateNextReviewDate
{
    // 取得离下一次复习的天数
    int dayInterval = [NewWord dayIntervalToNextReview:self.rememberLevel];
    
    // 更新下次复习时间
    DDLogVerbose(@"%@ 上次复习时间是 %@", self.word.spell, self.nextReviewDate);
    NSCalendar *gregorianClander = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = dayInterval;
    self.nextReviewDate =[gregorianClander dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
    DDLogVerbose(@"%@ 下次复习时间是 %@", self.word.spell, self.nextReviewDate);
}

- (NSString *)addDateString
{
    [self willAccessValueForKey:@"addDate"];
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        [formatter setLocale:locale];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
     }
    [self didAccessValueForKey:@"addDate"];
    return [formatter stringFromDate:self.addDate];
}
@end
