//
//  RDCUtils.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"

@implementation RDCUtils

+(NSString *)currentTimeStamp {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    
    return [formatter stringFromDate:[NSDate date]];
}

+(void)showAlertWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void (^)(NSModalResponse))completion
{
    NSAlert* alert = [[NSAlert alloc] init];
    
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = style;
    
    for (NSString* tlt in buttons)
        [alert addButtonWithTitle:tlt];
    
    NSModalResponse result = [alert runModal];
    
    if(completion != nil)
        completion(result);
    return ;
}

+(void)beginSheetAlertForWindow:(NSWindow *)window title:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style buttons:(NSArray<NSString *> *)buttons completion:(void (^)(NSModalResponse))completion
{
    NSAlert* alert = [[NSAlert alloc] init];
    
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = style;
    
    for (NSString* tlt in buttons)
        [alert addButtonWithTitle:tlt];
    return [alert beginSheetModalForWindow:window completionHandler:completion];
}

@end
