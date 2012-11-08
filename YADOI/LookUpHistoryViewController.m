//
//  LookUpHistoryViewController.m
//  YADOI
//
//  Created by HaiLee on 12-11-8.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "LookUpHistoryViewController.h"
#import "LookUpHistory+Utility.h"
#import "WordEntity+Utility.h"
#import "DDLog.h"

static const int ddLogLevel=LOG_LEVEL_VERBOSE;

@interface LookUpHistoryViewController ()<UISearchDisplayDelegate, UISearchBarDelegate>
- (IBAction)cancelClicked:(id)sender;
// 由于要用到缓存，每次改变fetchRequest条件时，重新生成一个fetchedResultsController，而不是在原来的上面改。
// searchString为空表示将显示全部历史，不为空表示只显示搜索的结果。
- (void)updateFetchedControllerWithSearchString:(NSString *)searchString;
// 选中了某个单词
- (void)selectWord:(WordEntity *)wordEntity;
@end

@implementation LookUpHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.title = @"编辑";
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

#pragma mark -
#pragma mark NSFetchedResultsController
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        [self setupFetchedResultsController];
    }
}

- (void)updateFetchedControllerWithSearchString:(NSString *)searchString
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LookUpHistory"];
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"onDate" ascending:NO];
    fetchRequest.sortDescriptors = @[dateSortDescriptor];
    
    NSPredicate *predicate = nil;
    NSString *cacheName = nil;
    
    if (searchString != nil && ![searchString isEqualToString:@""]) {
        predicate = [NSPredicate predicateWithFormat:@"word.spell beginswith[c] %@", searchString];
        cacheName = searchString;
    } else {
        predicate = nil;
        cacheName = @"AllHistory";
    }
    fetchRequest.predicate = predicate;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:@"addDateString" cacheName:cacheName];
    

}

- (void)setupFetchedResultsController
{
    [self updateFetchedControllerWithSearchString:nil];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"LookupHistoryCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    LookUpHistory *lookUpHistory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = lookUpHistory.word.spell;
    cell.detailTextLabel.text = [lookUpHistory.word stringForShortExplain];
    return cell;
}

// 没有SectionIndex;
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return 0;
}
// 可以编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        LookUpHistory *lookUpHistory = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [LookUpHistory deleteLookUpHistory:lookUpHistory];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LookUpHistory *lookUpHistory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self selectWord:lookUpHistory.word];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *trimedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimedSearchString != nil && ![trimedSearchString isEqualToString:@""])
    {
        [self updateFetchedControllerWithSearchString:trimedSearchString];
    }
    return YES;
}

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self updateFetchedControllerWithSearchString:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([self.fetchedResultsController.fetchedObjects count] != 0) {
        LookUpHistory *lookUpHistory = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
        [self selectWord:lookUpHistory.word];
    }
}
- (IBAction)cancelClicked:(id)sender {
    [self.delegate lookUpHistoryViewControllerCancelClicked:self];
}
- (void)selectWord:(WordEntity *)wordEntity
{
    [self.delegate lookUpHistoryViewController:self selectWord:wordEntity];
}
@end
