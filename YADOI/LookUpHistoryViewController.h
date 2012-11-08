//
//  LookUpHistoryViewController.h
//  YADOI
//
//  Created by HaiLee on 12-11-8.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "CoreDataTableViewController.h"
@class WordEntity;
@class LookUpHistoryViewController;

@protocol LookUpHistoryViewControllerDelegate <NSObject>
- (void)lookUpHistoryViewControllerCancelClicked:(LookUpHistoryViewController *)sender;
- (void)lookUpHistoryViewController:(LookUpHistoryViewController *)sender selectWord:(WordEntity *)wordEntity;
@end

@interface LookUpHistoryViewController : CoreDataTableViewController
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id<LookUpHistoryViewControllerDelegate> delegate;
@end
