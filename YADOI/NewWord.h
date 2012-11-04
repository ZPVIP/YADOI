//
//  NewWord.h
//  YADOI
//
//  Created by HaiLee on 12-11-4.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WordEntity;

@interface NewWord : NSManagedObject

@property (nonatomic, retain) NSDate * nextReviewDate;
@property (nonatomic, retain) NSNumber * rememberLevel;
@property (nonatomic, retain) NSDate * addDate;
@property (nonatomic, retain) NSString * addDateString;
@property (nonatomic, retain) WordEntity *word;

@end
