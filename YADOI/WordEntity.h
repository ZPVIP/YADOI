//
//  WordEntity.h
//  YADUtility
//
//  Created by HaiLee on 12-10-27.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WordExplain, WordSampleSentence;

@interface WordEntity : NSManagedObject

@property (nonatomic, retain) NSString * phonetic;
@property (nonatomic, retain) NSString * spell;
@property (nonatomic, retain) NSSet *explains;
@property (nonatomic, retain) NSSet *sampleSentences;
@end

@interface WordEntity (CoreDataGeneratedAccessors)

- (void)addExplainsObject:(WordExplain *)value;
- (void)removeExplainsObject:(WordExplain *)value;
- (void)addExplains:(NSSet *)values;
- (void)removeExplains:(NSSet *)values;

- (void)addSampleSentencesObject:(WordSampleSentence *)value;
- (void)removeSampleSentencesObject:(WordSampleSentence *)value;
- (void)addSampleSentences:(NSSet *)values;
- (void)removeSampleSentences:(NSSet *)values;

@end
