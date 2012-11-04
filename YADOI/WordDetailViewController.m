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
#import <AVFoundation/AVFoundation.h>
#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIDownloadCache.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordDetailViewController ()<ASIHTTPRequestDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) ASIHTTPRequest *request;

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
    self.phoneticLabel.text = [self.theWordEntity stringForPhonetic];
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

- (IBAction)readTheWord:(UIButton *)sender {
    NSString *wordSpell = self.theWordEntity.spell;
    // 取得发音地址
    NSString *requestString = [NSString stringWithFormat:@"http://translate.google.cn/translate_tts?ie=UTF-8&q=%@&tl=en", wordSpell];
    NSURL *audioURL = [NSURL URLWithString:[requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    DDLogVerbose(@"单词发音地址是:%@", audioURL);
    
    // 初始化请求
    self.request = [[ASIHTTPRequest alloc] initWithURL:audioURL];
    // 设置缓存
    [self.request setDownloadCache:[ASIDownloadCache sharedCache]];
    // 发音是不会变的
    [self.request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [self.request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    
    // 将自己设为request的delegate
    self.request.delegate = self;
    [self.request startAsynchronous];
}

// 请求成功
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

// 请求失败
- (void)requestFailed:(ASIHTTPRequest *)request
{
    DDLogError(@"连接超时，未能取得数据");
    // TODO:给出相关提示？
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
    [self setPhoneticLabel:nil];
    [self setExplainsTextView:nil];
    [self setSampleSentenceTextView:nil];
    [self setAddToNewWordBookButton:nil];
    [super viewDidUnload];
}

@end
