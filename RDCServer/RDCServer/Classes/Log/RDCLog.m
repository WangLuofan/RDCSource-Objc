//
//  RDCLog.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCUtils.h"
#import "RDCLog.h"

#define LOCK_BEGIN while([_theLock tryLock] == NO)
#define LOCK_END [_theLock unlock]

#define LOCK(block) do { \
LOCK_BEGIN; \
void (^handler)(void) = ^{ \
block \
}; \
handler(); \
LOCK_END; \
}while(0)

@implementation RDCLog

@end

@interface RDCLogList()

@property(nonatomic, strong) NSMutableArray* logList;
@property(nonatomic, strong) NSLock* theLock;

@end

static RDCLogList* _obj = nil;
@implementation RDCLogList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _logList = [NSMutableArray array];
        _theLock = [[NSLock alloc] init];
    }
    return self;
}

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _obj = [[RDCLogList alloc] init];
    });
    return _obj;
}

-(void)writeLog:(NSString *)content {
    LOCK({
        RDCLog* log = [[RDCLog alloc] init];
        
        log.content = content;
        log.timeStamp = [RDCUtils currentTimeStamp];
        
        [_logList addObject:log];
    });
    
    [RDCNotificationCenter postNotificationName:kNewLogWrittenNotification object:nil];
    return ;
}

-(void)clear {
    LOCK({
        [_logList removeAllObjects];
    });
    
    [RDCNotificationCenter postNotificationName:kNewLogWrittenNotification object:nil];
    return ;
}

-(RDCLog *)logAtIndex:(NSInteger)index {
    __block RDCLog* log = nil;
    LOCK({
        if(index > _logList.count)
            return ;
        log = [_logList objectAtIndex:index];
    });
    return log;
}

-(NSInteger)count {
    __block NSInteger length = 0;
    LOCK({
        length = _logList.count;
    });
    return length;
}

@end
