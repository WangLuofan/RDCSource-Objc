//
//  RDCMainWindowController.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"
#import "RDCServer.h"
#import "RDCLog.h"
#import "RDCConfiguration.h"
#import "RDCHostInfo.h"
#import "RDCClientInfo.h"
#import "RDCClientInfoList.h"
#import "RDCPreferenceWindowController.h"
#import "RDCMainWindowController.h"

#define kHostNameKey @"HostNameColumn"
#define kIPAddrKey @"IPAddressColumn"
#define kPortKey @"PortColumn"
#define kSysVerKey @"SystemVersionColumn"
#define kTokenKey @"TokenColumn"
#define kPassKey @"PasswordColumn"
#define kStatKey @"CurrentStatusColumn"
#define kOnlineKey @"OnlineTimestampColumn"

#define kLogTimeKey @"LogTimeStampColumn"
#define kLogCntKey @"LogContentColumn"

@interface RDCMainWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic, strong) RDCServer* theServer;
@property(nonatomic, weak) IBOutlet NSTableView* clientTableView;
@property(nonatomic, weak) IBOutlet NSTableView* logTableView;

@end

@implementation RDCMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self adjustTableViewToFit:
     self.window.contentView.frame.size.width];
    
    [RDCNotificationCenter addObserver:self selector:@selector(reloadMainTableView) name:kMainTableViewShouldReloadNotification object:nil];
    [RDCNotificationCenter addObserver:self selector:@selector(reloadLogTableView) name:kNewLogWrittenNotification object:nil];
    
    //启动服务器
    _theServer = [[RDCServer alloc] init];
    [_theServer start];
    return ;
}

-(void)reloadMainTableView {
    PerformOnMainThread({
        [_clientTableView reloadData];
    });
    return ;
}

-(void)reloadLogTableView {
    PerformOnMainThread({
        [_logTableView reloadData];
    });
    return ;
}

-(IBAction)preference:(NSMenuItem *)sender {
    RDCPreferenceWindowController* prefWindowController = [[RDCPreferenceWindowController alloc] init];
    [self.window beginSheet:prefWindowController.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSModalResponseOK)
        {
            //保存配置
            if([RDCConfiguration.standardConfiguration saveConfiguration] == NO)
            {
                [RDCUtils showAlertWithTitle:@"错误" message:@"保存配置失败" style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
            }
        }
    }];
    return ;
}

- (IBAction)closeWindow:(NSMenuItem *)sender {
    [self.window close];
    return ;
}

-(void)adjustTableViewToFit:(CGFloat)width {
    CGFloat itemWidth = width / _clientTableView.tableColumns.count;
    for (NSTableColumn* column in _clientTableView.tableColumns) {
        [column setWidth:itemWidth];
    }
    return ;
}

#pragma mark - NSWindowDelegate
-(void)windowWillClose:(NSNotification *)notification {
    //窗口关闭，释放资源
    [RDCClientInfoList.sharedInstance clear];
    //停止服务器
    [_theServer exit];
    return ;
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    [self adjustTableViewToFit:sender.contentView.frame.size.width];
    return frameSize;
}

#pragma mark - NSTableViewDelegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if([tableView isEqual:_clientTableView])
        return RDCClientInfoList.sharedInstance.count;
    return RDCLogList.sharedInstance.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString* identifier = tableColumn.identifier;
    NSString* value = nil;
    
    if([tableView isEqual:_clientTableView]) {
        RDCClientInfo* cliInfo = [RDCClientInfoList.sharedInstance clientInfoAtIndex:row];
        if([identifier isEqualToString:kHostNameKey]) {
            //主机名
            value = cliInfo.clientHostInfo.hostName;
        }else if([identifier isEqualToString:kIPAddrKey]) {
            //IP地址
            value = cliInfo.clientHostInfo.ipAddress;
        }else if([identifier isEqualToString:kPortKey]) {
            //端口号
            value = cliInfo.clientHostInfo.port;
        }else if([identifier isEqualToString:kSysVerKey]) {
            //系统信息
            value = cliInfo.clientSystemVersion;
        }else if([identifier isEqualToString:kTokenKey]) {
            //Token
            value = cliInfo.clientToken;
        }else if([identifier isEqualToString:kPassKey]) {
            //Password
            value = cliInfo.clientPassword;
        }else if([identifier isEqualToString:kStatKey]) {
            //当前状态
            value = cliInfo.clientStatusDescription;
        }else if([identifier isEqualToString:kOnlineKey]) {
            //上线时间
            value = cliInfo.onlineTimeStamp;
        }
    }else {
        RDCLog* log = [RDCLogList.sharedInstance logAtIndex:row];
        if([identifier isEqualToString:kLogTimeKey]) {
            value = log.timeStamp;
        }else if([identifier isEqualToString:kLogCntKey]) {
            value = log.content;
        }
    }
    
    return value;
}

@end
