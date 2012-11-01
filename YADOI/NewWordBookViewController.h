//
//  NewWordBookViewController.h
//  YADOI
//
//  Created by HaiLee on 12-10-31.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

@interface NewWordBookViewController : CoreDataTableViewController<UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedOjbectContext;
@end
