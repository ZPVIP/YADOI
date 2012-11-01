//
//  WordListViewController.h
//  YADOI
//
//  Created by HaiLee on 12-10-29.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "CoreDataInsetTableViewController.h"

@interface WordListViewController : CoreDataInsetTableViewController<UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
