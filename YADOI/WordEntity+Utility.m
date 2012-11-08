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
#import "NewWord.h"
#import "ASIHTTPRequest.h"
#import "LookUpHistory+Utility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

// 有道的API Key和 keyFrom
#define KEYFROM @"comcuter"
#define KEY     @"611168882"

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

- (NSString *)stringForPhonetic
{
    NSString *phonetic = self.phonetic;
    if (phonetic == nil) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"[%@]", self.phonetic];
    }
}

- (BOOL)isInTheNewWordBook
{
    BOOL isAdded = NO;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"NewWord"];
    request.predicate = [NSPredicate predicateWithFormat:@"word == %@", self];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word.spell" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *mathes = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DDLogError(@"执行 FetchRequest 时出错：%@", request);
        return NO;
    }
    
    if ([mathes count] == 1) {
        isAdded = YES;
    } else {
        isAdded = NO;
    }
    
    return isAdded;
}

- (void)addToTheNewWordBook
{
    // 判断是否已经在单词本中
    if ([self isInTheNewWordBook]) {
        DDLogWarn(@"%@ 已经在单词本中了", self.spell);
        return;
    }
    
    NewWord *newWord = [NSEntityDescription insertNewObjectForEntityForName:@"NewWord" inManagedObjectContext:self.managedObjectContext];
    newWord.word = self;
    newWord.rememberLevel = 0;
    // 加入单词本的时间
    newWord.addDate = [NSDate date];
    // 今天加入的单词下次复习时间是今天23点59（之前）
    NSDate *currentDate = [NSDate date];
    NSCalendar *gregorCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned unitFlag = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateCompents = [gregorCalendar components:unitFlag fromDate:currentDate];
    dateCompents.hour = 23;
    dateCompents.minute = 59;
    dateCompents.second = 59;
    NSDate *nextReviewDate = [gregorCalendar dateFromComponents:dateCompents];
    newWord.nextReviewDate = nextReviewDate;
    DDLogVerbose(@"单词添加到生词本中成功");
    [self saveContext];
}

- (void)removeFromWordBook
{
    if (![self isInTheNewWordBook]) {
        DDLogWarn(@"%@ 不在单词本中，不能删除", self.spell);
        return;
    }
    // 是的，没有双向关联真的很不方便。
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NewWord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"word == %@", self];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word.spell" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error != nil) {
        DDLogError(@"执行fetchRequest %@ 时出错", fetchRequest);
        return;
    }
    
    if (matches == nil || [matches count] > 1) {
        DDLogError(@"出错了, %@ 可能被多次加入到生词本中",self.spell);
    } else if ([matches count] == 1){
        [self.managedObjectContext deleteObject:[matches lastObject]];
        DDLogVerbose(@"成功将 %@ 从单词本删除", self.spell);
    }
    [self saveContext];
}


- (BOOL)saveContext
{
    NSError *error = nil;
    if (![self.managedObjectContext save:&error] || error != nil) {
        DDLogError(@"保存context时出错,%@, %@", [error localizedDescription], [error localizedFailureReason]);
        return NO;
    } 
   
    return YES;
}
- (NSString *)firstLetter
{
    return [[self.spell substringToIndex:1] uppercaseString];
}

+ (NSURL *)ttsURLForWord:(NSString *)word
{
    NSString *requestString = [NSString stringWithFormat:@"http://translate.google.cn/translate_tts?ie=UTF-8&q=%@&tl=en", word];
    NSURL *audioURL = [NSURL URLWithString:[requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    DDLogVerbose(@"单词发音地址是:%@", audioURL);
    return audioURL;
}

+ (void)queryNetWorkDicFor:(NSString *)searchString setDelegate:(id<WordEntityDelegate>)delegate
{
    NSString *requestFormatString = @"http://fanyi.youdao.com/openapi.do?keyfrom=%@&key=%@&type=data&doctype=json&version=1.1&q=%@";
    NSString *wordQueryString = [NSString stringWithFormat:requestFormatString, KEYFROM, KEY, searchString];
    NSURL *wordQueryURL = [NSURL URLWithString:[wordQueryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    DDLogVerbose(@"%@的请求地址是%@",searchString, wordQueryURL);
    
    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:wordQueryURL];
    
    [request setCompletionBlock:^{
        NSData *responseData = [request responseData];
        DDLogVerbose(@"Word Query Finish");
        if ([responseData length] > 10) {
            NSError *error = nil;
            id returnWords = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
            if (error != nil) {
                DDLogError(@"不能解析返回的数据%@, %@",[error localizedDescription],[error localizedFailureReason]);
            } else {
                NSDictionary *youDaoDic = nil;
                if ([returnWords isKindOfClass:[NSArray class]]) {
                    youDaoDic = [returnWords lastObject];
                } else if ([returnWords isKindOfClass:[NSDictionary class]]) {
                    youDaoDic = returnWords;
                }
                DDLogVerbose(@"返回的数据是Dictionary：%@", youDaoDic);
                // 将有道字典转成本地Model对应的类型
                NSDictionary *localWordJsonDic = [WordEntity contvertYouDaoJsonDicToLocalWordJsonDic:returnWords];
                // 将收到的结果返回
                [delegate queryNetWorkDicFinished:localWordJsonDic];
            }
        }
    
    }];
    
    [request setFailedBlock:^{
        DDLogError(@"Failed");
        [delegate queryNetWorkDicFailed:request.error];
    }];
    
    [request startAsynchronous];
}

// 将有道字典转化成本地Model对应的Dic,如果有错误，则返回nil
+ (NSDictionary *)contvertYouDaoJsonDicToLocalWordJsonDic:(NSDictionary *)youDaoDic
{
    NSString *trimedErrorCode = [[NSString stringWithFormat:@"%@", [youDaoDic valueForKey:@"errorCode"]]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DDLogVerbose(@"erorCode is %@", trimedErrorCode);
    // 返回状态码不为0
    if (![trimedErrorCode isEqualToString:@"0"]){
        return nil;
    }
    
    NSString *queryString = [youDaoDic valueForKey:@"query"];
    NSArray *translation = [youDaoDic valueForKey:@"translation"];
    NSString *translationString = [translation lastObject];
    NSArray *explains = [youDaoDic valueForKeyPath:@"basic.explains"];
    NSString *phonetic = [youDaoDic valueForKeyPath:@"basic.phonetic"];
    // 没有中文翻译结果，就不要了。
    if (queryString == nil || translationString == nil ||
        [queryString localizedCaseInsensitiveCompare:translationString] == NSOrderedSame || [explains count] == 0) {
        return nil;
    }
    
    // 正常情况，创建一个新的Dic并返回
    NSMutableDictionary *localDic = [NSMutableDictionary dictionary];
    if (queryString != nil) {
        [localDic setObject:queryString forKey:@"word"];
    }
    if (explains != nil) {
        [localDic setObject:explains forKey:@"explains"];
    }
    if (phonetic != nil) {
        [localDic setObject:phonetic forKey:@"phonetic"];
    }
    
    return localDic;
}

- (void)addToLookUpHistory
{
    [LookUpHistory addWordToLookUpHistory:self];
}

- (BOOL)IsInLookUpHistory
{
    return [LookUpHistory isThisWordInLookUpHistory:self];
}
@end
