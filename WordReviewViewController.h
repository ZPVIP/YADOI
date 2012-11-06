//
//  WordReviewViewController.h
//  YADOI
//
//  Created by HaiLee on 12-11-1.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WordReviewViewController : UIViewController

@property (nonatomic, strong) NSArray *wordsToReview; // WordEntity的数组

@property (weak, nonatomic) IBOutlet UILabel *wordSpellLabel;
@property (weak, nonatomic) IBOutlet UILabel *wordPhoneticLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *wordExplainTextView;


- (IBAction)rememberClicked:(UIButton *)sender;
- (IBAction)doNotRememberClicked:(UIButton *)sender;

@end
