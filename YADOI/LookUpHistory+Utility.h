//
//  LookUpHistory+Utility.h
//  YADOI
//
//  Created by HaiLee on 12-11-8.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "LookUpHistory.h"

@interface LookUpHistory (Utility)
- (NSString *)addDateString;
// 将一个单词加入查询历史记录
+ (void)addWordToLookUpHistory:(WordEntity *)wordEntity;
// 一个单词是否在历史记录中
+ (BOOL)isThisWordInLookUpHistory:(WordEntity *)wordEntity;
// 从历史记录中将一个LookUpHistory删除
+ (void)deleteLookUpHistory:(LookUpHistory *)lookUpHistory;
@end
