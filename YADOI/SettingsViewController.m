//
//  SettingsViewController.m
//  YADOI
//
//  Created by HaiLee on 12-11-4.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "SettingsViewController.h"
#import "DDLog.h"

const static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface SettingsViewController ()
- (IBAction)reviewWordOrderedChanged:(UISwitch *)sender;
- (IBAction)onlyUseLocalDicChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *reviewWordOrderedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *onlyUseLocalDicSwitch;
@property (weak, nonatomic) IBOutlet UILabel *dailyReviewWordNumberLabel;
@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 从用户设置里面获取数据来显示界面
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.reviewWordOrderedSwitch.on = [defaults boolForKey:REVIEW_WORD_ORDERED];
    self.onlyUseLocalDicSwitch.on = [defaults boolForKey:ONLY_USE_LOCAL_DIC];
    self.dailyReviewWordNumberLabel.text = [NSString stringWithFormat:@"%d个", [defaults integerForKey:DAILY_REVIEW_WORD_NUMBER]];
}

- (IBAction)reviewWordOrderedChanged:(UISwitch *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:sender.isOn forKey:REVIEW_WORD_ORDERED];
    [userDefaults synchronize];
    DDLogVerbose(@"用户修改复习时单词有序的设置，设置为:%@", sender.isOn ? @"YES" : @"NO");
}

- (IBAction)onlyUseLocalDicChanged:(UISwitch *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:sender.isOn forKey:ONLY_USE_LOCAL_DIC];
    [userDefaults synchronize];
    DDLogVerbose(@"用户修改使用本地字典的设置，设置为:%@", sender.isOn ? @"YES" : @"NO");
}

- (void)viewDidUnload {
    [self setReviewWordOrderedSwitch:nil];
    [self setOnlyUseLocalDicSwitch:nil];
    [self setDailyReviewWordNumberLabel:nil];
    [super viewDidUnload];
}
@end
