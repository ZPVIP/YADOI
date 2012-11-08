//
//  DailyReviewWordNumberViewController.m
//  YADOI
//
//  Created by HaiLee on 12-11-4.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "DailyReviewWordNumberViewController.h"
#import "SettingsKey.h"
#import "DDLog.h"

const static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface DailyReviewWordNumberViewController ()
- (IBAction)dailyReviewNumberChanged:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UILabel *showNumberLabel;
@property (weak, nonatomic) IBOutlet UISlider *numberSlider;
@end

@implementation DailyReviewWordNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    float reviewNumber = [[NSUserDefaults standardUserDefaults] integerForKey:DAILY_REVIEW_WORD_NUMBER];
    self.numberSlider.value = reviewNumber;
    [self showNumberLabelForValue:reviewNumber];
}

- (IBAction)dailyReviewNumberChanged:(UISlider *)sender {
    [self showNumberLabelForValue:sender.value];
}

- (void)showNumberLabelForValue:(float)currentValue
{
    // 调整Label的位置和值
    // 是的，这些都是肮脏的Magic Number,但是很容易懂
    CGRect numberLabelFrame = CGRectMake(-14 + 2.66 * currentValue, 0, 37, 21);
    self.showNumberLabel.frame = numberLabelFrame;
    
    int reviewNumber = (int)(currentValue / 10) * 10;
    self.showNumberLabel.text = [NSString stringWithFormat:@"%d个", reviewNumber];
}

// 保存reviewNumber
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int reviewNumber = (int)(self.numberSlider.value / 10) * 10;
    [defaults setInteger:reviewNumber forKey:DAILY_REVIEW_WORD_NUMBER];
    [defaults synchronize];
    
}
- (void)viewDidUnload {
    [self setShowNumberLabel:nil];
    [self setNumberSlider:nil];
    [super viewDidUnload];
}
@end
