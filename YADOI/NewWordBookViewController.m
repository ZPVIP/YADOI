//
//  NewWordBookViewController.m
//  YADOI
//
//  Created by HaiLee on 12-10-31.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "NewWordBookViewController.h"
#import "NewWord+Utility.h"
#import "WordEntity+Utility.h"
#import "WordDetailViewController.h"
#import "WordReviewViewController.h"
#import "DDLog.h"

const static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface NewWordBookViewController ()
// 排序及SectionTitle 显示
typedef enum {
    kOrderByDate = 0,
    kOrderByFirstLetter
} WordSortOrder;
@end

@implementation NewWordBookViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.title = @"编辑";
}

- (void)setupFetchedRequestsController
{
    // 默认是按日期排序，没有sectionIndex
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"NewWord"];
    [self changeOrderTo:kOrderByDate withRequest:request];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        [self setupFetchedRequestsController];
    }
}

- (IBAction)sortOrederChanged:(UISegmentedControl *)sender {
    NSInteger selectedIndex = sender.selectedSegmentIndex;
    // 按日期序
    if (selectedIndex == 0) {
        [self changeOrderTo:kOrderByDate withRequest:self.fetchedResultsController.fetchRequest];
    } else {
        [self changeOrderTo:kOrderByFirstLetter withRequest:self.fetchedResultsController.fetchRequest];
    }
}

// 修改列表中的单词排序。但是不会修改 NSPredicate，注意会修改self.fetchedRequestController.
- (void)changeOrderTo:(WordSortOrder)wordSortOrder withRequest:(NSFetchRequest *)fetchRequest
{
    static NSSortDescriptor *dateSortDescriptor = nil;
    static NSSortDescriptor *wordFirLetterSortDescriptor = nil;
    if (dateSortDescriptor == nil) {
        dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"addDate" ascending:NO];
    }
    if (wordFirLetterSortDescriptor == nil) {
        wordFirLetterSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word.spell"
                                                                    ascending:YES
                                                                     selector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    NSString *sectionNameKeyPath = nil;
    if (wordSortOrder == kOrderByDate) {
        fetchRequest.sortDescriptors = @[dateSortDescriptor,wordFirLetterSortDescriptor];
        sectionNameKeyPath = @"addDateString";
        DDLogVerbose(@"生词本页面改成按日期排序");
    } else if (wordSortOrder == kOrderByFirstLetter){
        fetchRequest.sortDescriptors = @[wordFirLetterSortDescriptor];
        sectionNameKeyPath = @"word.firstLetter";
        DDLogVerbose(@"生词本页面改成按首字母排序");
    }
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing) {
        self.editButtonItem.title = @"完成";
    } else {
        self.editButtonItem.title = @"编辑";
    }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NewWordCell";
    
    // 注意此处是 self.tableView 而不是 tableView 是因为这样两个tableView可以共用这些Cell.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NewWord *newWord = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = newWord.word.spell;
    cell.detailTextLabel.text = [newWord.word stringForShortExplain];
    return cell;
}

// 可以编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NewWord *theNewWord = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString *spell = theNewWord.word.spell; // 为删除日志用
        [self.managedObjectContext deleteObject:theNewWord];
        
        NSError *error = nil;
        if (![self.managedObjectContext save:&error] || error != nil) {
            DDLogError(@"从生词本删除 %@ 失败,%@,%@", spell, [error localizedDescription], [error localizedFailureReason]);
        } else {
            DDLogVerbose(@"从生词本删除 %@ 成功", spell);
        }
    }   
}

// 没有sectionIndex
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // 日期排序时没有Index
    NSMutableArray *sectionIndex = nil;
    if (self.sortOrderSegmentControl.selectedSegmentIndex == 0) {
         return nil;
    } else if (self.sortOrderSegmentControl.selectedSegmentIndex == 1 && [self numberOfSectionsInTableView:tableView] > 2) {
        return [self.fetchedResultsController sectionIndexTitles];
    }
    return sectionIndex;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if ([self sectionIndexTitlesForTableView:tableView] != nil) {
        return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
    } else {
        return 0;
    }
}

// 搜索功能 和 WordListViewController 相似
#pragma mark -
#pragma mark SearchDisplayDelegate
// 开始搜索时修改 fetchedResultsController.fetchRequest
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"word.spell beginswith[c] %@", searchString];
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        DDLogError(@"执行fetchRequest时失败, %@, %@, %@",
                   self.fetchedResultsController.fetchRequest, [error localizedDescription], [error localizedFailureReason]);
    }
    return YES;
}

// 点击 Cancel 时，将 fetchedResultsController.fetchRequst 改回来
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.fetchedResultsController.fetchRequest.predicate = nil;
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        DDLogError(@"执行fetchRequest时失败, %@, %@, %@",
                   self.fetchedResultsController.fetchRequest, [error localizedDescription], [error localizedFailureReason]);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showWordDetailFromWordBook"] && [sender isKindOfClass:[UITableViewCell class]]){
        // 查看生词
        UITableViewCell *senderCell = (UITableViewCell *)sender;
        
        NSIndexPath *indexPath = nil;
        if (senderCell.superview == self.tableView) {
            indexPath = [self.tableView indexPathForSelectedRow];
        } else {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        }
        
        NewWord *newWord = [self.fetchedResultsController objectAtIndexPath:indexPath];
        WordDetailViewController *detailVC = segue.destinationViewController;
        detailVC.theWordEntity = newWord.word;
    } else if ([segue.identifier isEqualToString:@"reviewWordBook"]){
        // 复习生词 取得要复习的生词
        NSArray *wordsToReview = [NewWord todaysReviewWordsWithContext:self.managedObjectContext];
        WordReviewViewController *reviewVC = segue.destinationViewController;
        // 如果单词本没有单词，则将其置 nil 以与今天已经复习完区别开
        // 同时需要注意的是，如果执行搜索时出错，那wordsToReview也是nil;
        if ([NewWord countOfNewWordWithConext:self.managedObjectContext] == 0) {
            reviewVC.wordsToReview = nil;
        } else {
            reviewVC.wordsToReview = wordsToReview;
        }
    }
}
- (void)viewDidUnload {
    [self setSortOrderSegmentControl:nil];
    [super viewDidUnload];
}
@end
