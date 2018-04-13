//
//  RDCGenericMarcos.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#ifndef RDCGenericMarcos_h
#define RDCGenericMarcos_h

#define WeakObject(obj) __typeof(obj) weak_##obj = obj;

#define RDCUserDefaults [NSUserDefaults standardUserDefaults]
#define RDCNotificationCenter [NSNotificationCenter defaultCenter]

#define PLATFORM_IOS @"iOS"
#define PLATFORM_MACINTOSH @"Mac"
#define PLATFORM_WINDOWS @"Win"
#define PLATFORM_LINUX @"Lin"

#define IS_PLATFORM_IOS(type) [type isEqualToString:PLATFORM_IOS]
#define IS_PLATFORM_MAC(type) [type isEqualToString:PLATFORM_MACINTOSH]
#define IS_PLATFORM_WIN(type) [type isEqualToString:PLATFORM_WINDOWS]
#define IS_PLATFORM_LIN(type) [type isEqualToString:PLATFORM_LINUX]

#define WriteLog(fmt, str) [RDCLogList.sharedInstance writeLog:[NSString stringWithFormat:fmt, str]]

#define PerformOnMainThread(CodeBlocks) do { \
    if([NSThread currentThread].isMainThread) { \
        void(^block)(void) = ^{ \
            CodeBlocks \
            return ; \
        }; \
        block(); \
    }else { \
        dispatch_async(dispatch_get_main_queue(), ^{ \
            CodeBlocks \
            return ; \
        }); \
    } \
}while(0)

#define PerformOnMainThreadDelay(delay, CodeBlocks) do { \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ \
        CodeBlocks \
    }); \
}while(0)

#endif /* RDCGenericMarcos_h */
