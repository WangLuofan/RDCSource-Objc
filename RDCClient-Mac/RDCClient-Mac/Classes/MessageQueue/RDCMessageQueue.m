//
//  RDCMessageQueue.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/28.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCMessageQueue.h"

#define LOCK_BEGIN [_theLock lock]
#define LOCK_END [_theLock unlock]

#define LOCK(code) LOCK_BEGIN; \
    do { \
        code \
    }while(0); \
LOCK_END

@interface RDCMessageQueue()

@property(nonatomic, strong) NSMutableArray* theQueue;
@property(nonatomic, strong) NSLock* theLock;

@end

@implementation RDCMessageQueue

- (instancetype)init
{
    self = [super init];
    if (self) {
        _theQueue = [NSMutableArray array];
        _theLock = [[NSLock alloc] init];
    }
    return self;
}

-(NSInteger)count {
    NSInteger length = 0;
    LOCK({
        length = _theQueue.count;
    });
    
    return  length;
}

-(void)push_back:(RDCMessage *)msg {
    if(msg == nil)
        return ;
    LOCK({
        [_theQueue addObject:msg];
    });
    return ;
}

-(BOOL)empty {
    BOOL bEmpty = YES;
    LOCK({
        bEmpty = (_theQueue.count == 0);
    });
    return bEmpty;
}

-(void)clear {
    LOCK({
        [_theQueue removeAllObjects];
    });
    
    return ;
}

-(RDCMessage *)pop_front {
    RDCMessage* msg = nil;
    LOCK({
        if(_theQueue.count != 0) {
            msg = _theQueue.firstObject;
            [_theQueue removeObjectAtIndex:0];
        }
    });
    
    return msg;
}

@end
