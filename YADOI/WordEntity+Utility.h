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
// 在单词列表中显示的解释
- (NSString *)stringForShortExplain;
// 在单词详细页显示的解释
- (NSString *)stringForDetailExplain;
// 在单词详细页显示的例句
- (NSString *)stringForSampleSentence;
// 音标字符串
- (NSString *)stringForPhonetic;
// 是否在单词本中
- (BOOL)isInTheNewWordBook;
// 把自己加入单词本
- (void)addToTheNewWordBook;
@end
