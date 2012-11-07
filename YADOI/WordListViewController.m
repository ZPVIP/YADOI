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
#import "SettingsKey.h"
#import "WordDetailViewController.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface WordListViewController ()<WordEntityDelegate>
// 为效率而做的一点优化，在输入一个字母0.7s后作检查，如果一致，则搜索，否则认为还在输入中，不搜索。
- (void)queryWordFromNet:(NSString *)searchString;
// WordEntityDelegate
- (void)queryNetWorkDicFinished:(NSDictionary *)wordEntityDic;
- (void)queryNetWorkDicFailed:(NSError *)error;

@property (nonatomic, strong) NSMutableArray *fetchedObjects;
@property (nonatomic, strong) NSMutableArray *filteredObjects;
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

- (void)setupFetchedObjects
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WordEntity"];
    request.fetchBatchSize = 20;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell"
                                                                     ascending:YES
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:@"All"];
    self.fetchedObjects = [NSMutableArray arrayWithCapacity:16000];
    [self.fetchedObjects addObjectsFromArray:self.fetchedResultsController.fetchedObjects];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        [self setupFetchedObjects];
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
    
    WordEntity *wordEntity = nil;
    if (tableView == self.tableView) {
        wordEntity = [self.fetchedObjects objectAtIndex:indexPath.row];
    } else {
        wordEntity = [self.filteredObjects objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = wordEntity.spell;
    // 只显示Explain的第一条结果
    cell.detailTextLabel.text = [wordEntity stringForShortExplain];
    // 只显示第一条结果
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [self.fetchedObjects count];
    } else {
        return [self.filteredObjects count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
#pragma mark -
#pragma mark UISearchDisplayDelegate
// 开始搜索时，显示的是searchDisplayController.searchResultsTableView,它与self.tableView共用DataSource和Delegate，
// 因此只需（只能）改动fetechedRequestController
// 先Quick and Dirty 地跑起来
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *trimedString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimedString != nil && ![trimedString isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"spell beginswith[c] %@", searchString];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell"
                                                                         ascending:YES
                                                                          selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *tempArray = [self.fetchedObjects filteredArrayUsingPredicate:predicate];
        tempArray = [tempArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.filteredObjects = [tempArray mutableCopy];
        // 依据用户设置来为判断是否启用网络查词
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:ONLY_USE_LOCAL_DIC]){
            // 如果条目数为0，则尝试到网络上取词,如果确实有这个单词，就加入到本地词库中
            if ([self.filteredObjects count] == 0) {
                [self performSelector:@selector(queryWordFromNet:) withObject:searchString afterDelay:0.7];
            }
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
        WordEntity *theNewWord = [WordEntity wordEntityWithJsonDictionary:wordEntityDic inManagedOjbectContext:self.managedObjectContext];
        [self.filteredObjects addObject:theNewWord];
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self.fetchedObjects addObject:theNewWord];
    }
}
- (void)queryNetWorkDicFailed:(NSError *)error
{
    DDLogVerbose(@"网络查词失败，做相应的提示");
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
        WordEntity *wordEntity = nil;
        if (senderCell.superview == self.tableView) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            wordEntity = [self.fetchedObjects objectAtIndex:indexPath.row];
        } else {
            NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            wordEntity = [self.filteredObjects objectAtIndex:indexPath.row];
        }
        WordDetailViewController *detailVC = segue.destinationViewController;
        detailVC.theWordEntity = wordEntity;
    }
}

@end
