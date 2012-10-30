//
//  WordSampleSentence+Create.h
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordSampleSentence.h"

@interface WordSampleSentence (Create)
+ (WordSampleSentence *)sampleSentenceWithDictionary:(NSDictionary *)dic
                                             forWord:(WordEntity *)wordEntity
                              inManagedObjectContext:(NSManagedObjectContext *)context;
@end
