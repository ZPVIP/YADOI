//
//  WordEntity+Creat.m
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordEntity+Utility.h"
#import "WordExplain+Utility.h"
#import "WordSampleSentence+Utility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_ERROR;

@implementation WordEntity (Utility)

+ (WordEntity *)wordEntityWithJsonDictionary:(NSDictionary *)jsonDictionary
                      inManagedOjbectContext:(NSManagedObjectContext *)context
{
    if (!jsonDictionary) {
        DDLogVerbose(@"创建词条时给定的 dictionary 为空，不能创建");
        return nil;
    }
    
    WordEntity *wordEntity = nil;
    
    NSString *wordSpell = [jsonDictionary objectForKey:@"word"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WordEntity"];
    request.predicate = [NSPredicate predicateWithFormat:@"spell = %@", wordSpell];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DDLogError(@"查询 wordEntity 时出错 %@", error);
        return nil;
    }
    
    if (matches == nil || [matches count] > 1) {
        DDLogError(@"查询 wordEntity 的结果不正常。");
        return nil;
    } else if ([matches count] == 0) {
        // 尚不存在，需要创建基本项
        wordEntity = [NSEntityDescription insertNewObjectForEntityForName:@"WordEntity" inManagedObjectContext:context];
        NSString *wordSpell = [jsonDictionary objectForKey:@"word"];
        wordEntity.spell = wordSpell;
        wordEntity.phonetic = [jsonDictionary objectForKey:@"phonetic"];
        DDLogVerbose(@"%@的基本项尚不存在，需要创建", wordSpell);
    } else {
        // 基本项已经存在，返回
        wordEntity = [matches lastObject];
        DDLogVerbose(@"%@的基本项已经存在", wordSpell);
    }
    
    // 尝试创建 explains（可能已经存在）.
    NSArray *explains = [jsonDictionary objectForKey:@"explains"];
    if (explains != nil) {
        for (NSString *explainString in explains) {
            WordExplain *explain = [WordExplain wordExplainWithString:explainString
                                                              forWord:wordEntity
                                               inManagedObjectContext:context];
            [wordEntity addExplainsObject:explain];
        }
    }
    
    // 尝试创建 sentence （可能已经存在）.
    NSArray *sampleSentences = [jsonDictionary objectForKey:@"sampleSentence"];
    if (sampleSentences != nil) {
        for (NSDictionary *sentenceDic in sampleSentences) {
            WordSampleSentence *sampleSentence = [WordSampleSentence sampleSentenceWithDictionary:sentenceDic
                                                                                          forWord:wordEntity
                                                                           inManagedObjectContext:context];
            [wordEntity addSampleSentencesObject:sampleSentence];
        }
    }

    
    return wordEntity;
    
}

// 在单词列表页面显示的解释
- (NSString *)stringForShortExplain
{
    NSSet *explains = self.explains;
    
    if (explains == nil) {
        return nil;
    }
    
    WordExplain *explain = [[explains objectEnumerator] nextObject];
    return explain.explain;
}

// 在单词详细页面显示的解释
- (NSString *)stringForDetailExplain
{
    NSSet *explains = self.explains;
    DDLogVerbose(@"explains count is :%d",[explains count]);
    if ([explains count] == 0) {
        return nil;
    }

    NSMutableString *resultString = [NSMutableString string];
    for (WordExplain *explain in explains) {
        [resultString appendFormat:@"%@ \n", explain.explain];
    }
    return [resultString substringToIndex:[resultString length] - 2];
}

// 在单词详细页面显示的例句
- (NSString *)stringForSampleSentence
{
    NSSet *sampleSentences = self.sampleSentences;
    DDLogVerbose(@"sampleSentence count is : %d", [sampleSentences count]);
    if ([sampleSentences count] == 0) {
        return nil;
    }
    
    NSMutableString *resultString = [NSMutableString string];
    NSUInteger idx = 0;
    
    for (WordSampleSentence *sampleSentence in sampleSentences) {
        [resultString appendFormat:@"%d.  %@\n%@\n\n", ++idx, sampleSentence.original, sampleSentence.translation];
    }

    return [resultString substringToIndex:[resultString length] - 2];
}
@end
