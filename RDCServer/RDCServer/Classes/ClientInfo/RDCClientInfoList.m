//
//  RDCClientInfoList.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCTcpSocket.h"
#import "RDCClientInfo.h"
#import "RDCClientInfoList.h"

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

@interface RDCClientInfoList()

@property(nonatomic, strong) NSLock* theLock;
@property(nonatomic, strong) NSMutableArray* infoList;

@end

static RDCClientInfoList* _obj = nil;
@implementation RDCClientInfoList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _infoList = [NSMutableArray array];
        _theLock = [[NSLock alloc] init];
    }
    return self;
}

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _obj = [[RDCClientInfoList alloc] init];
    });
    
    return _obj;
}

-(RDCClientInfo *)clientInfoWithSocket:(RDCTcpSocket *)socket {
    __block RDCClientInfo* cliInfo = nil;
    LOCK({
        for (RDCClientInfo* client in _infoList) {
            if([client.clientSocket isEqual:socket]) {
                cliInfo = client;
                break ;
            }
        }
    });
    
    return cliInfo;
}

-(RDCClientInfo *)clientInfoWithToken:(NSString*)token {
    __block RDCClientInfo* cliInfo = nil;
    LOCK({
        for (RDCClientInfo* client in _infoList) {
            if([client.clientToken isEqualToString:token]) {
                cliInfo = client;
                break ;
            }
        }
    });
    
    return cliInfo;
}

-(void)removeClientInfoAtIndex:(NSInteger)index {
    LOCK({
        if(index > _infoList.count)
            return ;
        [_infoList removeObjectAtIndex:index];
    });
    return ;
}

-(void)removeClientInfo:(RDCClientInfo *)cliInfo {
    LOCK({
        if(cliInfo == nil)
            return ;
        
        RDCClientInfo* peerInfo = cliInfo.peerClientInfo;
        if(peerInfo != nil) {
            peerInfo.peerClientInfo = nil;
            cliInfo.peerClientInfo = nil;
        }
        
        if([_infoList containsObject:cliInfo])
            [_infoList removeObject:cliInfo];
    });
    return ;
}

-(RDCClientInfo *)clientInfoAtIndex:(NSInteger)index {
    __block RDCClientInfo* cliInfo = nil;
    LOCK({
        if(index > _infoList.count)
            return ;
        cliInfo = [_infoList objectAtIndex:index];
    });
    
    return cliInfo;
}

-(void)appendClientInfo:(RDCClientInfo *)cliInfo {
    LOCK({
        if(cliInfo == nil)
            return ;
        [_infoList addObject:cliInfo];
    });
    return ;
}

-(NSInteger)count {
    __block NSInteger length = 0;
    LOCK({
        length = _infoList.count;
    });
    return length;
}

-(void)clear {
    LOCK({
        [_infoList removeAllObjects];
    });
    return ;
}

@end
