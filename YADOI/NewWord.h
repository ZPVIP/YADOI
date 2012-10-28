//
//  NewWord.h
//  YADUtility
//
//  Created by HaiLee on 12-10-27.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WordEntity;

@interface NewWord : NSManagedObject

@property (nonatomic, retain) NSDate * nextReviewDate;
@property (nonatomic, retain) NSNumber * rememberLevel;
@property (nonatomic, retain) WordEntity *word;

@end
