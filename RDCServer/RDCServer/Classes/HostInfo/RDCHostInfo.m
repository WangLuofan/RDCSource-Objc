//
//  RDCHostInfo.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#include <netinet/in.h>
#include <arpa/inet.h>

#import "RDCHostInfo.h"

@implementation RDCHostInfo

- (instancetype)initWithIPAddr:(NSString *)ipaddr port:(NSInteger)port host:(NSString *)host
{
    self = [super init];
    if (self) {
        _ipAddress = ipaddr;
        _port = [NSString stringWithFormat:@"%ld", (long)port];
        _hostName = host;
    }
    return self;
}

- (instancetype)initWithAddr:(struct sockaddr_in)addr
{
    self = [super init];
    if (self) {
        _port = [NSString stringWithFormat:@"%d", ntohs(addr.sin_port)];
        _ipAddress = [NSString stringWithUTF8String:inet_ntoa(addr.sin_addr)];
        _hostName = nil;
    }
    return self;
}

-(struct sockaddr_in)toNative {
    struct sockaddr_in addr;
    bzero(&addr, sizeof(struct sockaddr_in));
    
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_port = htons(_port.integerValue);
    
    inet_aton(_ipAddress.UTF8String, &addr.sin_addr);
    
    return addr;
}

@end
