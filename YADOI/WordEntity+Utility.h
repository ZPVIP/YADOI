//
//  WordEntity+Creat.h
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordEntity.h"

@interface WordEntity (Utility)

// 用一个 json 格式转换过来的 NSDictionary 来创建 WordEntity
+ (WordEntity *)wordEntityWithJsonDictionary:(NSDictionary *)jsonDictionary
                      inManagedOjbectContext:(NSManagedObjectContext *)context;

- (NSString *)stringForShortExplain;
- (NSString *)stringForDetailExplain;
- (NSString *)stringForSampleSentence;
// 是否在单词本中
- (BOOL)isInTheNewWordBook;
// 把自己加入单词本
- (void)addToTheNewWordBook;
@end
