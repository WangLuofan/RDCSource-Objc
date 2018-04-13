//
//  AppDelegate.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "AppDelegate.h"
#import "RDCConfiguration.h"
#import "RDCMainWindowViewController.h"
#import "RDCBaseNavigationController.h"
#import "Reachability.h"

#include <arpa/inet.h>

@interface AppDelegate ()

@property(nonatomic, strong) Reachability* hostReachability;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [RDCNotificationCenter addObserver:self selector:@selector(appReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(struct sockaddr));
    
    addr.sin_family = AF_INET;
    addr.sin_port = htons(RDCConfiguration.serverPort);
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_addr.s_addr = inet_addr([RDCConfiguration.serverAddr UTF8String]);
    
    _hostReachability = [Reachability reachabilityWithAddress:(const struct sockaddr*)&addr];
    [_hostReachability startNotifier];
    
    self.window = [[UIWindow alloc] initWithFrame:SCREEN_BOUNDS];
    
    RDCMainWindowViewController* mainController = [[RDCMainWindowViewController alloc] init];
    self.window.rootViewController = [[RDCBaseNavigationController alloc] initWithRootViewController:mainController];
    
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)dealloc
{
    [RDCNotificationCenter removeObserver:self];
}

-(void)appReachabilityChanged:(NSNotification*)notification {
    Reachability* reach = [notification object];
    if([reach isKindOfClass:[Reachability class]]) {
        NetworkStatus status = [reach currentReachabilityStatus];
        
        if([reach isEqual:_hostReachability]) {
            if(status == NotReachable) {
                
            }else if(status == ReachableViaWiFi) {
                
            }else if(status == ReachableViaWWAN) {
                
            }
        }
    }
    return ;
}

@end
