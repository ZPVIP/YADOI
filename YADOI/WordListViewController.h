//
//  WordListViewController.h
//  YADOI
//
//  Created by HaiLee on 12-10-29.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface WordListViewController : CoreDataTableViewController<UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic, strong) NSManagedObjectContext *context;
@end
