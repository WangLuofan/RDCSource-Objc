//
//  AppDelegate.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "AppDelegate.h"
#import "RDCMainWindowController.h"

@interface AppDelegate ()

@property(nonatomic, strong) RDCMainWindowController* mainWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _mainWindowController = [[RDCMainWindowController alloc] init];
    [_mainWindowController showWindow:nil];
    
    return ;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(IBAction)preferences:(id)sender {
    [_mainWindowController gotoPreferences];
    return ;
}

@end
