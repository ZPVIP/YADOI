//
//  WordEntity+Creat.m
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordEntity+Creat.h"
#import "WordExplain+Create.h"
#import "WordSampleSentence+Create.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation WordEntity (Creat)

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
@end
