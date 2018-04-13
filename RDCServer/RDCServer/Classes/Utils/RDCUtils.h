//
//  RDCUtils.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface RDCUtils : NSObject

+(NSString*)currentTimeStamp;
+(void)showAlertWithTitle:(NSString*)title message:(NSString*)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void(^)(NSModalResponse))completion;
+(void)beginSheetAlertForWindow:(NSWindow*)window title:(NSString*)title message:(NSString*)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void(^)(NSModalResponse))completion;

@end
