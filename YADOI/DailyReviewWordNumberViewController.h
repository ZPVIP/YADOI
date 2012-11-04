//
//  DailyReviewWordNumberViewController.h
//  YADOI
//
//  Created by HaiLee on 12-11-4.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DailyReviewWordNumberViewController : UITableViewController
- (IBAction)dailyReviewNumberChanged:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UILabel *showNumberLabel;
@property (weak, nonatomic) IBOutlet UISlider *numberSlider;

@end
