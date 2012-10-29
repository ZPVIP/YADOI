//
//  WordListViewController.m
//  YADOI
//
//  Created by HaiLee on 12-10-29.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "WordListViewController.h"
#import "WordEntity.h"
#import "WordExplain.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

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
    cell.detailTextLabel.text = [self getExplainStringFrom:wordEntity.explains];
    // 只显示第一条结果
    return cell;
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSFetchRequest *request = self.fetchedResultsController.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"spell beginswith[c] %@",searchString];
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    return YES;
}

// TODO: 把这个函数加到 WordEntity 里面，而不是放到这
- (NSString *)getExplainStringFrom:(NSSet*)explains
{
    if (explains == nil) {
        return nil;
    }
    
    WordExplain *explain = [[explains objectEnumerator] nextObject];
    return explain.explain;
}
@end
