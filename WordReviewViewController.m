//
//  WordReviewViewController.m
//  YADOI
//
//  Created by HaiLee on 12-11-1.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordReviewViewController.h"
#import "NewWord+Utility.h"
#import "WordEntity+Utility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordReviewViewController ()
@property (nonatomic, assign) NSInteger currendWordIndex; // 当前单词的 idx;

// 提示已经复习完所有单词
- (void)showAlreadyReviewAllWord;
@end

@implementation WordReviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 如果生词本没有单词，提示添加生词
    // TODO: 修改图片
    if (self.wordsToReview == nil) {
        // 去掉所有 View, 只显示一张图片
        NSArray *subViews = self.view.subviews;
        for (UIView *view in subViews) {
            if (![view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
            // TODO:使用Alert
        }
    } else if ([self.wordsToReview count] == 0) { // 今天的已经复习完，提示今天的已经复习完
        // 同样也是去掉所有 View，但是显示的图片不一样
        [self showAlreadyReviewAllWord];
    } else { // 正常情况
        // 初始化 idx
        self.currendWordIndex = -1;
        [self showNextWord];
    }
}


- (IBAction)rememberClicked:(UIButton *)sender {
    NewWord *currentWord = [self.wordsToReview objectAtIndex:self.currendWordIndex];
    // level 加 1,更新 Level.
    int currentRememberLevel = currentWord.rememberLevel.intValue;
    currentWord.rememberLevel = [NSNumber numberWithInt:(currentRememberLevel + 1)];
    
    // 更新下次复习时间
    [currentWord updateNextReviewDate];
    [self showNextWord];
}

- (IBAction)doNotRememberClicked:(UIButton *)sender {
    NewWord *currentWord = [self.wordsToReview objectAtIndex:self.currendWordIndex];
    [currentWord updateNextReviewDate];
    [self showNextWord];
}

- (void)showNextWord
{
    self.currendWordIndex++;
    if (self.currendWordIndex > [self.wordsToReview count] -1) {
        [self showAlreadyReviewAllWord];
    } else {
        NewWord *newWord = [self.wordsToReview objectAtIndex:self.currendWordIndex];
        WordEntity *theWordEntity = newWord.word;
        self.wordSpellLabel.text = theWordEntity.spell;
        self.wordPhoneticLabel.text = [theWordEntity stringForPhonetic];
        self.wordExplainTextView.text = [theWordEntity stringForDetailExplain];
    }
}

- (void)showAlreadyReviewAllWord
{
    NSArray *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if (![view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)viewDidUnload {
    [self setWordSpellLabel:nil];
    [self setWordPhoneticLabel:nil];
    [self setDisplayExplainImageView:nil];
    [self setWordExplainTextView:nil];
    [super viewDidUnload];
}
@end
