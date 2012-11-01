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
#import "NewWord.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordDetailViewController ()

@end

@implementation WordDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
    [self configureView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view
}

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
    
    // 判断该单词是否加入生词本
    [self.addToNewWordBookButton setTitle:@"Add" forState:UIControlStateNormal];
    [self.addToNewWordBookButton setTitle:@"Added" forState:UIControlStateDisabled];
    if ([self.theWordEntity isInTheNewWordBook]) {
        self.addToNewWordBookButton.enabled = NO;
    } else {
        self.addToNewWordBookButton.enabled = YES;
    }
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

// TODO:自己定义Cell，要不格子线太多了。
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.theWordEntity.sampleSentences count] == 0) {
        return 2;
    } else {
        return 3;
    }
    
}

// 将单词加入生词本
- (IBAction)addToNewWordBook:(UIButton *)sender {
    if (![self.theWordEntity isInTheNewWordBook]) {
        [self.theWordEntity addToTheNewWordBook];
        sender.enabled = NO;
    }
}

- (IBAction)readTheWord:(id)sender {
}


- (void)viewDidUnload {
    [self setWordSpellLabel:nil];
    [self setPhoneticLabel:nil];
    [self setExplainsTextView:nil];
    [self setSampleSentenceTextView:nil];
    [self setAddToNewWordBookButton:nil];
    [super viewDidUnload];
}

@end
