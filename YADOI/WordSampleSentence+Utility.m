//
//  WordSampleSentence+Create.m
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordSampleSentence+Utility.h"
#import "WordEntity.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation WordSampleSentence (Utility)
+ (WordSampleSentence *)sampleSentenceWithDictionary:(NSDictionary *)dic
                                             forWord:(WordEntity *)wordEntity
                              inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (dic == nil) {
        DDLogVerbose(@"创建例句时，给定的 dict 为空，不能创建");
        return nil;
    }
    
    WordSampleSentence *sampleSentence = nil;
    
    NSString *original = [dic objectForKey:@"original"];
    NSString *translation = [dic objectForKey:@"translation"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WordSampleSentence"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(word = %@) AND (original = %@)",wordEntity, original];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"original" ascending:YES];
    request.predicate = predicate;
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DDLogError(@"查询 WordSampleSentence 时出错，%@", error);
        return nil;
    }
    
    if (matches == nil || [matches count] > 1) {
        DDLogError(@"查询 WordSampleSentence 的结果不正常");
        return nil;
    } else if ([matches count] == 0) {
        sampleSentence = [NSEntityDescription insertNewObjectForEntityForName:@"WordSampleSentence" inManagedObjectContext:context];
        sampleSentence.original = original;
        sampleSentence.translation = translation;
        sampleSentence.word = wordEntity;
        DDLogVerbose(@"插入 %@ 的例句成功", wordEntity.spell);
    } else {
        sampleSentence = [matches lastObject];
        DDLogVerbose(@"%@的例句已经存在，未插入", wordEntity.spell);
    }
    
    
    return sampleSentence;
}
@end
