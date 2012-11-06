//
//  NewWord+Utility.h
//  YADOI
//
//  Created by HaiLee on 12-11-2.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "NewWord.h"

@interface NewWord (Utility)
// 取得今日要复习的单词的数组
+ (NSArray *)todaysReviewWordsWithContext:(NSManagedObjectContext *)managedObjectContext;
// 单词本中单词总数
+ (NSInteger)countOfNewWordWithConext:(NSManagedObjectContext *)managedObjectContext;
// 根据单词的 rememberLevel，更新下次复习时间
- (void)updateNextReviewDate;
// 该单词加入单词本的时间的String，作为sectionTitle用
- (NSString *)addDateString;
// 工具方法，因为没有地方放，临时放在这里
+ (NSString*)dateFormattedString:(NSDate *)date;
@end
