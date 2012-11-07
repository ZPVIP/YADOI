//
//  WordListViewController.m
//  YADOI
//
//  Created by HaiLee on 12-10-29.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordListViewController.h"
#import "WordEntity+Utility.h"
#import "WordExplain.h"
#import "DDLog.h"
#import "WordDetailViewController.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordListViewController ()<WordEntityDelegate>
// 为效率而做的一点优化，在输入一个字母0.3后作检查，如果一致，则搜索，否则认为还在输入中，不搜索。
- (void)queryWordFromNet:(NSString *)searchString;
// WordEntityDelegate
- (void)queryNetWorkDicFinished:(NSDictionary *)wordEntityDic;
- (void)queryNetWorkDicFailed:(NSError *)error;
@end

@implementation WordListViewController
@synthesize managedObjectContext = _managedObjectContext;
- (void)viewDidLoad
{
    [super viewDidLoad];
	if (self.managedObjectContext == nil) {
        DDLogError(@"出错了，MOC未能正常加载！");
        // 是否需要自己再加载次context呢？
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 相当于 TableViewController 的 clearSelectionOnViewWillAppear 效果。
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath != nil) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)setupFetchedRequestsController
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WordEntity"];
    request.fetchBatchSize = 20;
    request.fetchLimit = 0;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell"
                                                                     ascending:YES
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:@"All"];
}


- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
       [self setupFetchedRequestsController];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"WordEntityCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"WordEntityCell"];
    }
    
    WordEntity *wordEntity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = wordEntity.spell;
    // 只显示Explain的第一条结果
    cell.detailTextLabel.text = [wordEntity stringForShortExplain];
    // 只显示第一条结果
    return cell;
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
// 开始搜索时，显示的是searchDisplayController.searchResultsTableView,它与self.tableView共用DataSource和Delegate，
// 因此只需（只能）改动fetechedRequestController
// 先Quick and Dirty 地跑起来
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // 如果是空格则不查询
    NSString *trimedString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimedString != nil && ![trimedString isEqualToString:@""]) {
        NSFetchRequest *fetchRequest = self.fetchedResultsController.fetchRequest;
        fetchRequest.fetchBatchSize = 20;
        fetchRequest.fetchLimit = 50;
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"spell beginswith[c] %@",searchString];
        self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                         initWithFetchRequest:fetchRequest
                                         managedObjectContext:self.managedObjectContext
                                         sectionNameKeyPath:nil cacheName:searchString];
        // 如果条目数为0，则尝试到网络上取词,如果存在就加入到本地词库中
        if ([self.fetchedResultsController.fetchedObjects count] == 0) {
            [self performSelector:@selector(queryWordFromNet:) withObject:searchString afterDelay:0.7];
        }
    }
    return YES;
}

- (void)queryWordFromNet:(NSString *)searchString
{
    NSString *currentSearchString = self.searchDisplayController.searchBar.text;
    DDLogVerbose(@"现在搜索框字符串是: %@", currentSearchString);
    DDLogVerbose(@"传入的字符串是:%@",searchString);
    if ([currentSearchString isEqualToString:searchString]) {
        DDLogVerbose(@"两者相同开始搜索");
        [WordEntity queryNetWorkDicFor:searchString setDelegate:self];
    }
}

- (void)queryNetWorkDicFinished:(NSDictionary *)wordEntityDic
{
    if (wordEntityDic == nil) {
        DDLogVerbose(@"查询有结果，但结果不满意，不插入数据库");
    } else {
        DDLogVerbose(@"查询成功，将数据插入数据库");
        [WordEntity wordEntityWithJsonDictionary:wordEntityDic inManagedOjbectContext:self.managedObjectContext];
    }
}
- (void)queryNetWorkDicFailed:(NSError *)error
{
    DDLogVerbose(@"网络查词失败，做相应的提示");
}
#pragma mark -
#pragma mark UISearchBarDelegate
// 这时显示的是self.tableView,需要把 fetchRequest改回来。
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self setupFetchedRequestsController];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    DDLogVerbose(@"textDidChange");
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    DDLogVerbose(@"textDidEndEditing");
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    DDLogVerbose(@"textDidBeginEditing");
}
#pragma mark -
#pragma mark Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showWordDetail"] && [sender isKindOfClass:[UITableViewCell class]]) {
        // 需要判断是从哪个 tableView 进行segue的
        UITableViewCell *senderCell = sender;
        DDLogVerbose(@"segue from %@",(senderCell.superview == self.tableView) ?
                     @"self.tableView" : @"self.searchDisplayController.searchResultsTableView");
        NSIndexPath *indexPath = nil;
        if (senderCell.superview == self.tableView) {
            indexPath = [self.tableView indexPathForSelectedRow];
        } else {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        }
        
        DDLogVerbose(@"the indexPath is %@: ", indexPath);
        WordEntity *wordEntity = [self.fetchedResultsController objectAtIndexPath:indexPath];
        WordDetailViewController *detailVC = segue.destinationViewController;
        detailVC.theWordEntity = wordEntity;
    }
}

@end
