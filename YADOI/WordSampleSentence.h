//
//  WordSampleSentence.h
//  YADUtility
//
//  Created by HaiLee on 12-10-27.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WordEntity;

@interface WordSampleSentence : NSManagedObject

@property (nonatomic, retain) NSString * original;
@property (nonatomic, retain) NSString * translation;
@property (nonatomic, retain) WordEntity *word;

@end
