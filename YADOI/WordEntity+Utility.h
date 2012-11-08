//
//  WordEntity+Creat.h
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordEntity.h"

// 和 Word 相关的一些异步操作放到这里面，比如从网络取词
@protocol WordEntityDelegate <NSObject>
@optional
// 当从网络取词成功时调用,返回的是一个由Json转化过来的Dictionary,可以直接插入到数据库中
- (void)queryNetWorkDicFinished:(NSDictionary *)wordEntityDic;
// 取词失败时调用
- (void)queryNetWorkDicFailed:(NSError *)error;
@end

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
// 将自己从单词本中删除
- (void)removeFromWordBook;
// 判断是否在历史记录中
- (BOOL)IsInLookUpHistory;
// 将自己加入到历史记录中
- (void)addToLookUpHistory;
// 单词发音地址
+ (NSURL *)ttsURLForWord: (NSString*)word;
// 用给定的字符串从网络取词,如果存在就加入到数据库中。
// 查询完成后会调用 delegate的相应方法，以做近一步处理
+ (void)queryNetWorkDicFor: (NSString *)searchString setDelegate:(id<WordEntityDelegate>)delegate;
@end
