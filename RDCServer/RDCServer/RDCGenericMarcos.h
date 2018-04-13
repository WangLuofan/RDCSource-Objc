//
//  RDCGenericMarcos.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#ifndef RDCGenericMarcos_h
#define RDCGenericMarcos_h

#define RDCUserDefaults [NSUserDefaults standardUserDefaults]
#define RDCNotificationCenter [NSNotificationCenter defaultCenter]

#define kMainTableViewShouldReloadNotification @"MainTableViewShouldReloadNotification"
#define kNewLogWrittenNotification @"NewLogWrittenNotification"

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
