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
#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIDownloadCache.h"
#import <AVFoundation/AVFoundation.h>
#import "Reachability.h"
#import "SettingsKey.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordReviewViewController ()<ASIHTTPRequestDelegate,AVAudioPlayerDelegate>
@property (nonatomic, assign) NSInteger currentWordIndex; // 当前单词的 idx;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) ASIHTTPRequest *request;
// 用来辅助保证乱序，但是不重复的数组。
@property (nonatomic, strong) NSMutableArray *randomArray;

// 提示已经复习完所有单词
- (void)showAlreadyReviewAllWord;
// 单词发音
- (void)readTheWord:(UIButton *)sender;
// 将今天已经复习的单词数加1
- (void)addOneToTodayReviewWordNumber;
// 取得下一个idx,会根据是否有序而不同
- (NSInteger)nextWordIndex;
@end

@implementation WordReviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 如果生词本没有单词，提示添加生词
    if (self.wordsToReview == nil) {
        // 去掉所有 View, 只显示一张提示图片
        NSArray *subViews = self.view.subviews;
        for (UIView *view in subViews) {
            if (![view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
        }
        self.imageView.image = [UIImage imageNamed:@"noNewWordWarning.png"];
        // 今天的已经复习完，提示今天的已经复习完
    } else if ([self.wordsToReview count] == 0) {
        [self showAlreadyReviewAllWord];
    } else { // 正常情况
        // 初始化 idx
        self.currentWordIndex = -1;
        [self showNextWord];
        // 对图片添加点击显示释义功能。
        self.imageView.image = [UIImage imageNamed:@"showExplain.png"];
        self.imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showWordExplain:)];
        [self.imageView addGestureRecognizer:tapGesture];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)setWordsToReview:(NSArray *)wordsToReview
{
    
    if (_wordsToReview != wordsToReview) {
        _wordsToReview = wordsToReview;
    }
    
     // // 每重设一次wordsToReview就重新生成一次辅助数组
    if (_wordsToReview != nil && [_wordsToReview count] > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for(int i = 0; i < [_wordsToReview count]; i++) {
            [array addObject:[NSNumber numberWithInt:i]];
        }
        _randomArray = array;
    }
}


- (IBAction)rememberClicked:(UIButton *)sender {
    NewWord *currentWord = [self.wordsToReview objectAtIndex:self.currentWordIndex];
    // level 加 1,更新 Level.
    int currentRememberLevel = currentWord.rememberLevel.intValue;
    currentWord.rememberLevel = [NSNumber numberWithInt:(currentRememberLevel + 1)];
    
    // 更新下次复习时间
    [currentWord updateNextReviewDate];
    [self showNextWord];
    [self addOneToTodayReviewWordNumber];
}

- (IBAction)doNotRememberClicked:(UIButton *)sender {
    NewWord *currentWord = [self.wordsToReview objectAtIndex:self.currentWordIndex];
    [currentWord updateNextReviewDate];
    [self showNextWord];
    [self addOneToTodayReviewWordNumber];
}

- (void)showNextWord
{
    self.currentWordIndex = [self nextWordIndex];
    if (self.currentWordIndex == -1) {
        [self showAlreadyReviewAllWord];
    } else {
        NewWord *newWord = [self.wordsToReview objectAtIndex:self.currentWordIndex];
        WordEntity *theWordEntity = newWord.word;
        self.wordSpellLabel.text = theWordEntity.spell;
        
        // 发音按钮
        // 取得单词Label的大小
        // 首先把以前的去掉
        [[self.view viewWithTag:100] removeFromSuperview];
        CGSize wordLabelSize = [theWordEntity.spell sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:25]
                                               constrainedToSize:CGSizeMake(320, 30) lineBreakMode:NSLineBreakByCharWrapping];
        UIButton *readWordButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + wordLabelSize.width, 25, 69, 69)];
        [readWordButton setImage:[UIImage imageNamed:@"tts.png"] forState:UIControlStateNormal];
        readWordButton.imageEdgeInsets = UIEdgeInsetsMake(23, 23, 23, 23);
        // 设置 tag 以便以后查找
        readWordButton.tag = 100;
        [self.view addSubview:readWordButton];
        [readWordButton addTarget:self action:@selector(readTheWord:) forControlEvents:UIControlEventTouchUpInside];
        
        self.wordPhoneticLabel.text = [theWordEntity stringForPhonetic];
        self.wordExplainTextView.text = [theWordEntity stringForDetailExplain];
        // 显示点击显示释义
        self.wordExplainTextView.alpha = 0;
    }
}

- (NSInteger)nextWordIndex
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isOrdered = [defaults boolForKey:REVIEW_WORD_ORDERED];
    
    int nextWordIndex = 0;
    if (isOrdered) {
        nextWordIndex = ++self.currentWordIndex;
        if (nextWordIndex >= [self.wordsToReview count]) {
            nextWordIndex = -1;
        }
        DDLogVerbose(@"下一个单词顺序是%d", nextWordIndex);
    } else {
        // 已经到头了
        if ([self.randomArray count] == 0) {
            nextWordIndex = -1;
        } else {
            int indexOfnextWordIndex = arc4random() % [self.randomArray count];
            nextWordIndex = ((NSNumber *)[self.randomArray objectAtIndex:indexOfnextWordIndex]).intValue;
            DDLogVerbose(@"下一个单词顺序是%d", nextWordIndex);
            [self.randomArray removeObjectAtIndex:indexOfnextWordIndex];
        }
    }
    return nextWordIndex;
}
- (void)showWordExplain:(UITapGestureRecognizer *)gestureRecognizer
{
    [UIView animateWithDuration:0.4 animations:^{
        self.wordExplainTextView.alpha = 1;
    }];
}

- (void)showAlreadyReviewAllWord
{
    NSArray *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if (![view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    self.imageView.image = [UIImage imageNamed:@"alreadyReviewAll.png"];
    // 去掉点击事件
    [self.imageView removeGestureRecognizer:[self.imageView.gestureRecognizers lastObject]];
}

- (void)addOneToTodayReviewWordNumber
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *todaysReviewedNumberDic = [defaults objectForKey:TODAY_ALREADAY_REVIEWED_NUMBER];
    // 如果今天还没有复习过，那么重设该项的值为新的Dictionary.
    NSNumber *todaysReviewedNumber = [todaysReviewedNumberDic objectForKey:[NewWord dateFormattedString:[NSDate date]]];
    if (todaysReviewedNumber == nil) {
        DDLogVerbose(@"今天还没有复习过单词,现在复习的是第一个");
        todaysReviewedNumber = [NSNumber numberWithInt:1];
    } else {
        DDLogVerbose(@"今天已经复习过%d个单词，将其变成%d个单词",todaysReviewedNumber.intValue, todaysReviewedNumber.intValue + 1);
        todaysReviewedNumber = [NSNumber numberWithInt:(todaysReviewedNumber.intValue + 1)];
    }
    [defaults setObject:@{[NewWord dateFormattedString:[NSDate date]]:todaysReviewedNumber} forKey:TODAY_ALREADAY_REVIEWED_NUMBER];
    [defaults synchronize];
}

- (void)readTheWord:(UIButton *)sender
{
    WordEntity *theWordEntity = ((NewWord *)[self.wordsToReview objectAtIndex:self.currentWordIndex]).word;
    // 初始化请求
    self.request = [[ASIHTTPRequest alloc] initWithURL:[WordEntity ttsURLForWord:theWordEntity.spell]];
    // 设置缓存
    [self.request setDownloadCache:[ASIDownloadCache sharedCache]];
    // 发音是不会变的
    [self.request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [self.request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    // 设置超时重试次数
    [self.request setNumberOfTimesToRetryOnTimeout:2];
    
    // 将自己设为request的delegate
    self.request.delegate = self;
    [self.request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    DDLogVerbose(@"正常返回，取得发音");
    DDLogVerbose(@"%@", [request didUseCachedResponse] ? @"使用了缓存" : @"没有使用缓存");
    NSData *responseData = [request responseData];
    if (responseData != nil && [responseData length] > 0 && self.view.window) {
        NSError *error = nil;
        self.player = [[AVAudioPlayer alloc] initWithData:responseData error:&error];
        self.player.delegate = self;
        // 数据是否正常加载
        if (error == nil) {
            [self.player play];
        } else {
            DDLogError(@"播放器初始化失败");
        }
    } else {
        DDLogError(@"取回的发音文件不正常");
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    DDLogError(@"连接超时，未能取得数据");
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"发音失败"
                                                            message:@"可能是网络无连接，或者数据错误"
                                                           delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    DDLogVerbose(@"播放结束,清理播放器");
    self.player = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.request != nil && [self.request isExecuting]) {
        [self.request clearDelegatesAndCancel];
    }
}

- (void)viewDidUnload {
    [self setWordSpellLabel:nil];
    [self setWordPhoneticLabel:nil];
    [self setImageView:nil];
    [self setWordExplainTextView:nil];
    [super viewDidUnload];
}
@end
