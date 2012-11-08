//
//  WordDetailViewController.h
//  YADOI
//
//  Created by HaiLee on 12-10-30.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WordEntity;

@interface WordDetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) WordEntity *theWordEntity;
// 是否记录查词历史，从单词列表，单词列表搜索框及历史记录过来的，记录，否则不记录
@property (nonatomic, assign) BOOL recordHistory;
@end
