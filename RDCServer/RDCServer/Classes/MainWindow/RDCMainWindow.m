//
//  RDCMainWindow.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"
#import "RDCMainWindow.h"

@implementation RDCMainWindow

-(void)close {
    [RDCUtils beginSheetAlertForWindow:self title:@"关闭程序" message:@"确认要退出远程控制服务端吗?" style:NSAlertStyleWarning buttons:@[@"退出", @"取消"] completion:^(NSModalResponse returncode) {
        if(returncode == NSAlertFirstButtonReturn) {
            [super close];
        }
    }];
    return ;
}

@end
