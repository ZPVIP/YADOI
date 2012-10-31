//
//  WordDetailViewController.m
//  YADOI
//
//  Created by HaiLee on 12-10-30.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordDetailViewController.h"
#import "WordEntity+Utility.h"
#import "WordExplain+Utility.h"
#import "WordSampleSentence+Utility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordDetailViewController ()

@end

@implementation WordDetailViewController
// 调整页面
- (void)configureView
{
    if (self.theWordEntity == nil) {
        DDLogError(@"出错了，单词详细页面单词没有设置！");
        return;
    }
    // 设置标题
    self.title = self.theWordEntity.spell;
    // 设置基本项
    self.wordSpellLabel.text = self.theWordEntity.spell;
    NSString *phonetic = self.theWordEntity.phonetic;
    if (phonetic != nil) {
        self.phoneticLabel.text = [NSString stringWithFormat:@"[%@]", self.theWordEntity.phonetic];
    } else {
        self.phoneticLabel.text = nil;
    }

    // 解释
    self.explainsTextView.text = [self.theWordEntity stringForDetailExplain];
    
    // 例句
    self.sampleSentenceTextView.text = [self.theWordEntity stringForSampleSentence];
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 调整解释的高度
    NSString *explainsString = [self.theWordEntity stringForDetailExplain];
    CGSize explainSize = [explainsString sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:18]
                                    constrainedToSize:CGSizeMake(320, 220)];
    // 例句的高度
    NSString *sampleSentences = [self.theWordEntity stringForSampleSentence];
    CGSize sentenceSize = [sampleSentences sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:13]
                                    constrainedToSize:CGSizeMake(320, 220)];
    
    CGFloat height = 0;
    switch (indexPath.row) {
        case 0:
            height = 80;
            break;
        case 1:
            height = explainSize.height + 20;
            break;
        case 2:
            height = sentenceSize.height + 20;
            break;
    }
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.theWordEntity.sampleSentences count] == 0) {
        return 2;
    } else {
        return 3;
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [self configureView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self configureView];
}


- (void)viewDidUnload {
    [self setWordSpellLabel:nil];
    [self setPhoneticLabel:nil];
    [self setExplainsTextView:nil];
    [self setSampleSentenceTextView:nil];
    [super viewDidUnload];
}
@end
