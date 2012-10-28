//
//  LookUpHistory.h
//  YADUtility
//
//  Created by HaiLee on 12-10-27.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WordEntity;

@interface LookUpHistory : NSManagedObject

@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSDate * onDate;
@property (nonatomic, retain) WordEntity *word;

@end
