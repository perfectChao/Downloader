//
//  AppDelegate.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "AppDelegate.h"
#import "KSDownloader.h"
#import "HWNetworkReachabilityManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[HWNetworkReachabilityManager shareManager] monitorNetworkStatus];
    return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    _backgroundSessionCompletionHandler = completionHandler;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // 实现如下代码，才能使程序处于后台时被杀死，调用applicationWillTerminate:方法
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(){}];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[KSDownloader sharedDownloader] updateDownloadingTaskState];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


@end
