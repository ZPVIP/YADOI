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
#import "Reachability.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordDetailViewController ()<ASIHTTPRequestDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) ASIHTTPRequest *request;

// 传入一张图片的名字，显示，然后淡出，用来提示添加到单词本或者从单词本删除成功
-(void)showAddOrRemoveTip:(NSString *)imageName;

// 在画面中央显示提示，主要是发音时的提示
- (void)showTipInCenter:(NSString *)imageName;
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

- (void)configureView
{
    if (self.theWordEntity == nil) {
        DDLogError(@"出错了，单词没有设置");
        return;
    }
    
    // 右上角的加入单词本按钮
    NSString *imageName = nil;
    if ([self.theWordEntity isInTheNewWordBook]) {
        imageName = @"removeFromWordBook";
    } else {
        imageName = @"addToWordBook";
    }
    
    UIBarButtonItem *addToOrDeleteFromWordBookButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                                                                        style:UIBarButtonItemStyleBordered
                                                                                       target:self
                                                                                       action:@selector(addToOrRemoveFromWordBook)];
    self.navigationItem.rightBarButtonItem = addToOrDeleteFromWordBookButton;
    
    // 标题
    self.title = self.theWordEntity.spell;
    
    // 单词本身
    NSString *spell = self.theWordEntity.spell;
    CGSize spellLabelSize = [spell sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:25]
                              constrainedToSize:CGSizeMake(320, 30) lineBreakMode:NSLineBreakByCharWrapping];
    UILabel *spellLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 20, spellLabelSize.width, spellLabelSize.height)];
    spellLabel.text = spell;
    spellLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
    spellLabel.textColor = [UIColor colorWithRed:3/255.0 green:162/255.0 blue:62/255.0 alpha:1.0];
    [self.scrollView addSubview:spellLabel];
    //DDLogVerbose(@"spell Label frame :%@", NSStringFromCGRect(spellLabel.frame));
    
    // 发音按钮
    UIButton *readButton = [[UIButton alloc] initWithFrame:CGRectMake(5 + spellLabelSize.width, 2, 69, 69)];
    [readButton setImage:[UIImage imageNamed:@"tts.png"] forState:UIControlStateNormal];
    readButton.imageEdgeInsets = UIEdgeInsetsMake(23, 23, 23, 23);
    //DDLogVerbose(@"readButton Label frame: %@", NSStringFromCGRect(readButton.frame));
    // 绑定事件
    [readButton addTarget:self action:@selector(readTheWord:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:readButton];
    // 音标
    NSString *phoneticString = [self.theWordEntity stringForPhonetic];
    CGSize phoneticLabelSize = [phoneticString sizeWithFont:[UIFont fontWithName:@"Helvetica" size:18]
                                          constrainedToSize:CGSizeMake(320, 30) lineBreakMode:NSLineBreakByCharWrapping];
    UILabel *phoneticLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 50, phoneticLabelSize.width, phoneticLabelSize.height)];
    phoneticLabel.text = phoneticString;
    phoneticLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    phoneticLabel.textColor = [UIColor colorWithRed:155/255.0 green:105/255.0 blue:155/255.0 alpha:1.0];
    [self.scrollView addSubview:phoneticLabel];
    //DDLogVerbose(@"phonetic Label frame: %@", NSStringFromCGRect(phoneticLabel.frame));

    // 添加一条横线
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 80, 320, 2)];
    lineView.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0];
    [self.scrollView addSubview:lineView];
    
    // 单词解释
    NSString *explainsString = [self.theWordEntity stringForDetailExplain];
    CGSize explainsSize = [explainsString sizeWithFont:[UIFont fontWithName:@"Helvetica" size:18]
                                    constrainedToSize:CGSizeMake(295, 9999) lineBreakMode:NSLineBreakByCharWrapping];
    //DDLogVerbose(@"explain size is %@", NSStringFromCGSize(explainsSize));
    UITextView *explainsView = [[UITextView alloc] initWithFrame:CGRectMake(25, 82, 295, explainsSize.height/22 * 30)];
    explainsView.text = explainsString;
    explainsView.editable = NO;
    explainsView.scrollEnabled = NO;
    explainsView.font = [UIFont fontWithName:@"Helvetica" size:18];
    //DDLogVerbose(@"explain frame is %@", NSStringFromCGRect(explainsView.frame));
    [self.scrollView addSubview:explainsView];
    
    // 如果有例句，添加一条横线，然后是例句
    if ([self.theWordEntity.sampleSentences count] != 0) {
        // 相关例句Label
        UILabel *sampleSentenceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 95 + explainsView.frame.size.height, 320, 25)];
        sampleSentenceLabel.backgroundColor = [UIColor colorWithRed:217/255.0 green:236/255.0 blue:255/255.0 alpha:1.0];
        sampleSentenceLabel.text = @"   相关例句";
        sampleSentenceLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        [self.scrollView addSubview:sampleSentenceLabel];
        //DDLogVerbose(@"secondLineview frame is :%@", NSStringFromCGRect(sampleSentenceLabel.frame));
    
        // 例句
        NSString *sampleSentenceString = [self.theWordEntity stringForSampleSentence];
        UITextView *sampleSentenceView = [[UITextView alloc]
                                          initWithFrame:CGRectMake(0, 120 + explainsView.frame.size.height, 320, 20)];
        sampleSentenceView.text = sampleSentenceString;
        sampleSentenceView.editable = NO;
        sampleSentenceView.scrollEnabled = NO;
        sampleSentenceView.font = [UIFont fontWithName:@"Helvetica" size:14];
        [self.scrollView addSubview:sampleSentenceView];
        // 调整例句frame 两种调整UITextView 高度的方法，注意该种方法需要在 addSubView后才能使用。
        CGRect sampleSentenceFrame = sampleSentenceView.frame;
        sampleSentenceFrame.size.height = sampleSentenceView.contentSize.height;
        sampleSentenceView.frame = sampleSentenceFrame;
        //DDLogVerbose(@"sampleSentence frame is %@", NSStringFromCGRect(sampleSentenceView.frame));

        // 最后调整下scrollView 大小，让其可以滚动
        // 对 iPhone 5 做调整
        CGRect scrollFrame;
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (screenBounds.size.height == 568) {
            scrollFrame = CGRectMake(0, 0, 320, 455);
        } else {
            scrollFrame = CGRectMake(0, 0, 320, 367);
        }
        // 由搜索页面segue过来的,navigationBarHidden是YES,但是实际上还是显示的。scrollView frame大小其实包括 navigationBar。
        if (self.navigationController.navigationBarHidden) {
            scrollFrame.size.height += 44;
        }
        
        self.scrollView.frame = scrollFrame;
        [self.scrollView setContentSize:CGSizeMake(320, 120 + explainsView.frame.size.height + sampleSentenceView.frame.size.height)];
        //DDLogVerbose(@"scroll contentsize is %@", NSStringFromCGSize(self.scrollView.contentSize));
        //DDLogVerbose(@"scrollView frame is %@", NSStringFromCGRect(self.scrollView.frame));
    }
}

- (void)readTheWord:(UIButton *)sender {
    // 显示提示语
    [self showTipInCenter:@"voice_query.png"];
    // 初始化请求
    self.request = [[ASIHTTPRequest alloc] initWithURL:[WordEntity ttsURLForWord:self.theWordEntity.spell]];
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
            [self showTipInCenter:@"pronouncing.png"];
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

- (void)addToOrRemoveFromWordBook
{
    if ([self.theWordEntity isInTheNewWordBook]) {
        [self.theWordEntity removeFromWordBook];
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"addToWordBook"];
        [self showAddOrRemoveTip:@"wordDeleted.png"];
    } else {
        [self.theWordEntity addToTheNewWordBook];
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"removeFromWordBook"];
        [self showAddOrRemoveTip:@"wordAdded.png"];
    }
}

- (void)showAddOrRemoveTip:(NSString *)imageName
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    CGFloat imageHeight = imageView.image.size.height;
    CGFloat imageWidth = imageView.image.size.width;
    // 又见 Magic Number;
    imageView.frame = CGRectMake((320-imageWidth)/2, 367 - imageHeight, imageWidth, imageHeight);
    [self.view addSubview:imageView];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        imageView.frame = CGRectMake((320-imageWidth)/2, 367-imageHeight-75, imageWidth, imageHeight);
    } completion:^(BOOL finished){
        // 淡出
        [UIView animateWithDuration:1.2 animations:^{
            imageView.alpha = 0;
        } completion:^(BOOL finished){
            [imageView removeFromSuperview];
        }];
    }];
}

- (void)showTipInCenter:(NSString *)imageName
{
    [[self.view viewWithTag:200] removeFromSuperview];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    CGFloat imageHeight = imageView.image.size.height;
    CGFloat imageWidth = imageView.image.size.width;
    imageView.tag = 200;
    imageView.frame = CGRectMake((320-imageWidth)/2, 260, imageWidth, imageHeight);
    [self.view addSubview:imageView];
    [UIView animateWithDuration:1.2 animations:^{
        imageView.alpha = 0;
    } completion:^(BOOL finished){
        [imageView removeFromSuperview];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.request != nil && [self.request isExecuting]) {
        [self.request clearDelegatesAndCancel];
    }
}

- (void)viewDidUnload {
    [self setScrollView:nil];
    [super viewDidUnload];
}

@end
