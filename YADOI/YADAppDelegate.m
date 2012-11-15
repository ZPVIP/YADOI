//
//  YADAppDelegate.m
//  YADOI
//
//  Created by HaiLee on 12-10-27.
//  Copyright (c) 2012年 HaiLee. All rights reserved.
//

#import "YADAppDelegate.h"
#import <CoreData/CoreData.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "WordEntity.h"
#import "NewWord+Utility.h"
#import "WordListViewController.h"
#import "NewWordBookViewController.h"
#import "SettingsKey.h"

const static int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation YADAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupDDLog];
    // 加入第一次启动(firstLaunch)的标志字段
    [[NSUserDefaults standardUserDefaults]registerDefaults:@{@"firstLaunch":[NSNumber numberWithBool:YES]}];
    // 如果是第一次启动，预置用户的设置项
    if ([self isFirstLaunch]) {
        DDLogVerbose(@"是第一次启动，预置用户设置项");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:REVIEW_WORD_ORDERED];
        [defaults setBool:NO forKey:ONLY_USE_LOCAL_DIC];
        [defaults setInteger:30 forKey:DAILY_REVIEW_WORD_NUMBER];
        // 设置为今天还没有复习单词，具体见SettingsKey.h
        [defaults setObject:@{[NewWord dateFormattedString:[NSDate date]]:[NSNumber numberWithInt:0]}
                     forKey:TODAY_ALREADAY_REVIEWED_NUMBER];
        [defaults synchronize];
    } else {
        DDLogVerbose(@"不是第一次启动了，使用用户设置的数据");
    }
    
    
    UITabBarController *rootViewController = (UITabBarController *)[self.window rootViewController];
    
    // 单词列表和查词页面
    UINavigationController *lookupWordNVC = [rootViewController.viewControllers objectAtIndex:0];
    WordListViewController *wordListVC = (WordListViewController *)lookupWordNVC.topViewController;
    wordListVC.managedObjectContext = self.managedObjectContext;
    
    // 生词本页面
    UINavigationController *wordBookNVC = [rootViewController.viewControllers objectAtIndex:1];
    NewWordBookViewController *wordBookVC = (NewWordBookViewController *)wordBookNVC.topViewController;
    wordBookVC.managedObjectContext = self.managedObjectContext;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self saveContext];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DDLogVerbose(@"第一次启动设置成NO");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DDLogVerbose(@"firstLaunch设置成NO");
}

- (void)setupDDLog
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

- (void)testQuery
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WordEntity"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"spell" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error == nil) {
        DDLogVerbose(@"查询成功 共有条目数 %d", [matches count]);
    }

}

- (void)testInsert
{
    WordEntity *testWord = [NSEntityDescription insertNewObjectForEntityForName:@"WordEntity" inManagedObjectContext:self.managedObjectContext];
    testWord.spell = @"testststst";
    [self testQuery];
    
    [self.managedObjectContext deleteObject:testWord];
    [self testQuery];
}

// 是否是第一次启动
- (BOOL)isFirstLaunch
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *context = self.managedObjectContext;
    if (context != nil) {
        if ([context hasChanges]) {
            if (![context save:&error]) {
                DDLogError(@"保存context时出错，%@ %@", error, [error userInfo]);
            } else {
                DDLogVerbose(@"成功保存context");
            }
        }
    }
}

#pragma mark -
#pragma mark Core Data Stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    // 将 sqlite 从 mainBundle 里拷出来，变成可写的。
    NSURL *storeURL = [[self applicationDocumentDirectory] URLByAppendingPathComponent:@"YAD.sqlite"];
    DDLogVerbose(@"单词数据库storeURL is %@", storeURL);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        DDLogVerbose(@"第一次启动，拷贝数据库");
        NSURL *preLoadURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"YAD" ofType:@"sqlite"]];
        DDLogVerbose(@"预置数据库preLoadURL is %@", preLoadURL);
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] copyItemAtURL:preLoadURL toURL:storeURL error:&error]) {
            DDLogError(@"从mainBundle 拷贝数据库时出错");
        } else {
            DDLogVerbose(@"从 mainBundle 拷贝数据成功");
        }
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // 处理出错的情况，目前暂不处理
        // 主要有两种情况 1.storeURL 处文件不存在或者不可写 2.Model的版本问题，最简单的解决办法是删了重来，没有多版本。
        DDLogError(@"不能成功创建 persistentStoreCoordinator %@ %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YADMD" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSURL *)applicationDocumentDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
