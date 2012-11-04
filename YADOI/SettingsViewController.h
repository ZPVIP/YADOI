//
//  SettingsViewController.h
//  YADOI
//
//  Created by HaiLee on 12-11-4.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsKey.h"

@interface SettingsViewController : UITableViewController
- (IBAction)getPhoneticFromNetWorkChanged:(UISwitch *)sender;
- (IBAction)onlyUseLocalDicChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *getPhoneticFromNetWorkSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *onlyUseLocalDicSwitch;
@property (weak, nonatomic) IBOutlet UILabel *dailyReviewWordNumberLabel;
@end
