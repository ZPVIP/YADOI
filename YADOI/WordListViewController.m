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

static const int ddLogLevel = LOG_LEVEL_ERROR;

@interface WordListViewController ()

@end

@implementation WordListViewController
@synthesize context = _context;
- (void)viewDidLoad
{
    [super viewDidLoad];
	if (self.context == nil) {
        DDLogError(@"出错了，MOC未能正常加载！");
        // 是否需要自己再加载次context呢？
    }
}

- (void)setupFetchedRequestsController
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WordEntity"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell"
                                                                     ascending:YES
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (void)setContext:(NSManagedObjectContext *)context
{
    if (_context != context) {
        _context = context;
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
    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"spell beginswith[c] %@",searchString];
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error != nil) {
        DDLogError(@"执行这个fetchRequest时出错:%@", self.fetchedResultsController.fetchRequest);
    }
    DDLogVerbose(@"fetchRequest.predicate is (%@)", self.fetchedResultsController.fetchRequest.predicate);
    return YES;
}

#pragma mark -
#pragma mark UISearchBarDelegate
// 这时显示的是self.tableView,需要把 fetchRequest改回来。
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.fetchedResultsController.fetchRequest.predicate = nil;
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error != nil) {
        DDLogError(@"执行这个fetchRequest时出错:%@", self.fetchedResultsController.fetchRequest);
    }
    DDLogVerbose(@"fetchRequest.predicate is (%@)",self.fetchedResultsController.fetchRequest.predicate);
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
