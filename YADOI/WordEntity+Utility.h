//
//  WordEntity+Creat.h
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordEntity.h"

@interface WordEntity (Creat)

// 用一个 json 格式转换过来的 NSDictionary 来创建 WordEntity
+ (WordEntity *)wordEntityWithJsonDictionary:(NSDictionary *)jsonDictionary
                      inManagedOjbectContext:(NSManagedObjectContext *)context;
@end
