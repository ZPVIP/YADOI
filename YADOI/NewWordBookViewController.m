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
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"NewWord"];
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"addDate" ascending:YES];
    NSSortDescriptor *wordAsscendingSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word.spell"
                                                                     ascending:YES
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = @[dateSortDescriptor, wordAsscendingSortDescriptor];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedOjbectContext
                                                                          sectionNameKeyPath:@"addDateString"
                                                                                   cacheName:nil];

}

- (void)setManagedOjbectContext:(NSManagedObjectContext *)managedOjbectContext
{
    if (_managedOjbectContext != managedOjbectContext) {
        _managedOjbectContext = managedOjbectContext;
        [self setupFetchedRequestsController];
    }
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
        [self.managedOjbectContext deleteObject:theNewWord];
        
        NSError *error = nil;
        if (![self.managedOjbectContext save:&error] || error != nil) {
            DDLogError(@"从生词本删除 %@ 失败,%@,%@", spell, [error localizedDescription], [error localizedFailureReason]);
        } else {
            DDLogVerbose(@"从生词本删除 %@ 成功", spell);
        }
    }   
}

// 没有sectionIndex
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return 0;
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
        NSArray *wordsToReview = [NewWord todaysReviewWordsWithContext:self.managedOjbectContext];
        WordReviewViewController *reviewVC = segue.destinationViewController;
        // 如果单词本没有单词，则将其置 nil 以与今天已经复习完区别开
        // 同时需要注意的是，如果执行搜索时出错，那wordsToReview也是nil;
        if ([NewWord countOfNewWordWithConext:self.managedOjbectContext] == 0) {
            reviewVC.wordsToReview = nil;
        } else {
            reviewVC.wordsToReview = wordsToReview;
        }
    }
}
@end
