//
//  WordExplain+Create.h
//  YADUtility
//
//  Created by HaiLee on 12-10-28.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordExplain.h"

@interface WordExplain (Create)
+ (WordExplain *)wordExplainWithString:(NSString *)explainString
                               forWord:(WordEntity *)wordEntity
                inManagedObjectContext:(NSManagedObjectContext *)context;
@end
