//
//  RDCTcpSocket.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#import "RDCMessage.h"
#import "RDCHostInfo.h"
#import "RDCTcpSocket.h"

@interface RDCTcpSocket()

@end

@implementation RDCTcpSocket

- (instancetype)initSocketCreate
{
    self = [super init];
    if (self) {
        _fileDescriptor = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    }
    return self;
}

-(instancetype)initWithFileDescriptor:(int)fileDescriptor {
    self = [super init];
    if(self) {
        _fileDescriptor = fileDescriptor;
    }
    return self;
}

-(void)sendMessage:(const void *)msg length:(NSInteger)length {
    const char* ptr = (const char*)msg;
    int bytes_sended = 0;
    
    do {
        ptr += bytes_sended;
        bytes_sended = send(_fileDescriptor, ptr, length - bytes_sended, 0);
    }while(bytes_sended < length);
    
    return ;
}

-(void)sendMessage:(RDCMessage*)msg {
    return [self sendMessage:msg.data.bytes length:msg.size];
}

-(void)shutdown {
    if(_fileDescriptor != -1)
    {
        shutdown(_fileDescriptor, SHUT_RDWR);
        _fileDescriptor = -1;
    }
    
    return ;
}

-(void)connectToHost:(NSString *)host Port:(unsigned short)port {
    RDCHostInfo* hostInfo = [[RDCHostInfo alloc] initWithIPAddr:host port:port host:nil];
    return [self connectToHost:hostInfo];
}

-(void)connectToHost:(RDCHostInfo *)hostInfo {
    struct sockaddr_in addr = hostInfo.toNative;
    
    if(connect(_fileDescriptor, (const struct sockaddr*)&addr, sizeof(struct sockaddr)) != 0)
    {
        if([self.delegate respondsToSelector:@selector(errorOccuredOnSocket:desc:)])
        {
            [self.delegate errorOccuredOnSocket:self desc:[NSString stringWithUTF8String:strerror(errno)]];
            return ;
        }
    }
    
    //设置非阻塞
//    int flag = fcntl(_fileDescriptor, F_GETFL, 0);
//    fcntl(_fileDescriptor, F_SETFL, flag | O_NONBLOCK);
    
    if([self.delegate respondsToSelector:@selector(connectedToServerOnSocket:)])
    {
        [self.delegate connectedToServerOnSocket:self];
    }
    return ;
}

-(void)receiveMessage {
    RDCMessage* msg = [RDCMessage message];
    unsigned char* buffer = (unsigned char*)malloc(sizeof(unsigned char) * BUFSIZ * 100);
    @autoreleasepool {
//        ssize_t bytes_received = 0;
//        do {
//            memset(buffer, 0, BUFSIZ);
//            bytes_received = recv(_fileDescriptor, buffer, sizeof(unsigned char) * BUFSIZ, 0);
//            if(bytes_received > 0)
//                [msg appendData:buffer length:bytes_received];
//        }while(bytes_received > 0);
//
//        if(msg.data.length > 0) {
//            if([self.delegate respondsToSelector:
//                @selector(messageReceivedOnSocket:message:)])
//            {
//                [self.delegate messageReceivedOnSocket:self message:msg];
//            }
//        }
//        [msg clear];
        ssize_t bytes_received = recv(_fileDescriptor, buffer, sizeof(unsigned char) * BUFSIZ * 100, 0);
        if(bytes_received > 0) {
           [msg appendData:buffer length:bytes_received];
            if([self.delegate respondsToSelector:
                @selector(messageReceivedOnSocket:message:)])
            {
                [self.delegate messageReceivedOnSocket:self message:msg];
            }
            [msg clear];
        }
    }
    
    return ;
}

#pragma mark - 事件回调
-(void)accept_call_back:(int)fd addr:(struct sockaddr*)addr
{
    //新socket, Read/Write
    RDCTcpSocket* newSocket = [[RDCTcpSocket alloc] initWithFileDescriptor:fd];
    RDCHostInfo* hostInfo = [[RDCHostInfo alloc] initWithAddr:*((struct sockaddr_in*)addr)];
    
    if([self.delegate respondsToSelector:
        @selector(clientConnectedWithOnNewSocket:addr:)])
    {
        [self.delegate clientConnectedWithOnNewSocket:newSocket addr:hostInfo];
    }
    
    return ;
}

-(void)error_call_back
{
    if([self.delegate respondsToSelector:
        @selector(errorOccuredOnSocket:desc:)])
        [self.delegate errorOccuredOnSocket:self desc:[NSString stringWithUTF8String:strerror(errno)]];
    return ;
}

#pragma mark - 回调函数
void accept_call_back(int fd, struct sockaddr* addr, int socklen, void* userdata)
{
    RDCTcpSocket* socket = (__bridge RDCTcpSocket*)userdata;
    if(socket != nil)
        [socket accept_call_back:fd addr:addr];
    return ;
}

@end
