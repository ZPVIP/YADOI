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

@end
