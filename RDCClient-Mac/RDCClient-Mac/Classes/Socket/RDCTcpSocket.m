//
//  RDCTcpSocket.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#include <event2/event.h>
#include <event2/buffer.h>
#include <event2/bufferevent.h>
#include <event2/listener.h>
#include <event2/thread.h>
#include <event2/util.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#import "RDCMessage.h"
#import "RDCHostInfo.h"
#import "RDCTcpSocket.h"

@interface RDCTcpSocket() {
    struct event_base* m_pEventBase;
    struct evconnlistener* m_pConnListener;
    struct bufferevent* m_pBufferEvent;
}

@end

@implementation RDCTcpSocket

- (instancetype)initWithFileDescriptor:(int)fileDescriptor
{
    self = [super init];
    if (self) {
        _fileDescriptor = fileDescriptor;
    }
    return self;
}

-(void)sendMessage:(const void *)msg length:(NSInteger)length {
    struct evbuffer* output = bufferevent_get_output(m_pBufferEvent);
    evbuffer_add(output, msg, length);
    
    return ;
}

-(void)sendMessage:(RDCMessage*)msg {
    struct evbuffer* output = bufferevent_get_output(m_pBufferEvent);
    evbuffer_add(output, msg.data.bytes, msg.size);
    
    return ;
}

-(void)shutdown {
    if(self.delegate != nil)
        self.delegate = nil;

    if(m_pConnListener != NULL)
    {
        evconnlistener_free(m_pConnListener);
        m_pConnListener = NULL;
    }
    
    if(_fileDescriptor != -1)
    {
        evutil_closesocket(_fileDescriptor);
        _fileDescriptor = -1;
    }
    
    return ;
}

-(void)close
{
    [self shutdown];
    if(m_pEventBase != NULL)
    {
        if(event_base_loopexit(m_pEventBase, NULL) == 0) {
            event_base_free(m_pEventBase);
            m_pEventBase = NULL;
        }
    }
    
    return ;
}

-(void)listenAtPort:(NSInteger)port {
    evthread_use_pthreads();
    m_pEventBase = event_base_new();
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(struct sockaddr_in));
    
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;
    
    void accept_call_back(struct evconnlistener*, evutil_socket_t, struct sockaddr*, int, void*);
    m_pConnListener = evconnlistener_new_bind(m_pEventBase, accept_call_back, (__bridge void*)self, LEV_OPT_REUSEABLE | LEV_OPT_CLOSE_ON_FREE, 5, (const struct sockaddr*)&addr, sizeof(struct sockaddr));
    
    void error_call_back(struct evconnlistener*, void*);
    evconnlistener_set_error_cb(m_pConnListener, error_call_back);
    
    //启动事件循环
    event_base_dispatch(m_pEventBase);
    return ;
}

-(void)connectToHost:(NSString *)host Port:(unsigned short)port {
    RDCHostInfo* hostInfo = [[RDCHostInfo alloc] initWithIPAddr:host port:port host:nil];
    return [self connectToHost:hostInfo];
}

-(void)connectToHost:(RDCHostInfo *)hostInfo {
    evthread_use_pthreads();
    m_pEventBase = event_base_new();
    
    struct sockaddr_in addr = hostInfo.toNative;
    
    m_pBufferEvent = bufferevent_socket_new(m_pEventBase, -1, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_THREADSAFE);
    
    void read_call_back(struct bufferevent*, void*);
    void event_dispatch_call_back(struct bufferevent*, short, void*);
    
    bufferevent_setcb(m_pBufferEvent, read_call_back, NULL, event_dispatch_call_back, (__bridge void*)self);
    bufferevent_enable(m_pBufferEvent, EV_READ | EV_WRITE | EV_PERSIST);
    bufferevent_socket_connect(m_pBufferEvent, (const struct sockaddr*)&addr, sizeof(struct sockaddr));
    event_base_dispatch(m_pEventBase);
    return ;
}

#pragma mark - 事件回调
-(void)accept_call_back:(evutil_socket_t)fd addr:(struct sockaddr*)addr
{
    //新socket, Read/Write
    RDCTcpSocket* newSocket = [[RDCTcpSocket alloc] initWithFileDescriptor:fd];
    RDCHostInfo* hostInfo = [[RDCHostInfo alloc] initWithAddr:*((struct sockaddr_in*)addr)];
    
    newSocket->m_pBufferEvent = bufferevent_socket_new(m_pEventBase, fd, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_THREADSAFE);
    bufferevent_enable(newSocket->m_pBufferEvent, EV_READ | EV_WRITE | EV_PERSIST);
    
    void read_call_back(struct bufferevent*, void*);
    void event_dispatch_call_back(struct bufferevent*, short, void*);
    bufferevent_setcb(newSocket->m_pBufferEvent, read_call_back, NULL, event_dispatch_call_back, (__bridge void*)newSocket);
    
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

//接收到数据
-(void)read_call_back {
    @autoreleasepool {
        struct evbuffer* input = bufferevent_get_input(m_pBufferEvent);
        size_t len = evbuffer_get_length(input);
        
        RDCMessage* msg = [RDCMessage message];
        //读取数据
        unsigned char* buf = (unsigned char*)malloc(len);
        memset(buf, 0, len);
        evbuffer_remove(input, buf, len);
        
        [msg appendData:buf length:len];
        free(buf);
        
        if([self.delegate respondsToSelector:
            @selector(messageReceivedOnSocket:message:)])
            [self.delegate messageReceivedOnSocket:self message:msg];
    }
    return ;
}

-(void)event_dispatch_call_back:(short)what {
    if(what & BEV_EVENT_CONNECTED)
    {
        //成功连接到服务器
        if([self.delegate respondsToSelector:
            @selector(connectedToServerOnSocket:)])
            [self.delegate connectedToServerOnSocket:self];
        return ;
    }
    else if(what & BEV_EVENT_EOF)
    {
        //连接已断开
        if([self.delegate respondsToSelector:
            @selector(clientDisconnectedOnSocket:)])
            [self.delegate clientDisconnectedOnSocket:self];
    }
    else if(what & BEV_EVENT_TIMEOUT)
    {
        //超时
        if([self.delegate respondsToSelector:
            @selector(timeOutEventOccuredOnSocket:)])
            [self.delegate timeOutEventOccuredOnSocket:self];
    }
    else
    {
        //其他错误发生
        if([self.delegate respondsToSelector:
            @selector(errorOccuredOnSocket:desc:)])
            [self.delegate errorOccuredOnSocket:self desc:[NSString stringWithUTF8String:strerror(errno)]];
    }
    
    if(m_pBufferEvent != NULL) {
        bufferevent_free(m_pBufferEvent);
        m_pBufferEvent = NULL;
    }
    return ;
}

#pragma mark - 回调函数
void accept_call_back(struct evconnlistener* listener, evutil_socket_t fd, struct sockaddr* addr, int socklen, void* userdata)
{
    RDCTcpSocket* socket = (__bridge RDCTcpSocket*)userdata;
    if(socket != nil)
        [socket accept_call_back:fd addr:addr];
    return ;
}

void error_call_back(struct evconnlistener* listener, void* userdata)
{
    RDCTcpSocket* socket = (__bridge RDCTcpSocket*)userdata;
    if(socket != nil)
        [socket error_call_back];
    return ;
}

void read_call_back(struct bufferevent* bvt, void* userdata)
{
    RDCTcpSocket* socket = (__bridge RDCTcpSocket*)userdata;
    if(socket != nil)
        [socket read_call_back];
    return ;
}

void event_dispatch_call_back(struct bufferevent* bvt, short what, void* userdata)
{
    RDCTcpSocket* socket = (__bridge RDCTcpSocket*)userdata;
    if(socket != nil)
        [socket event_dispatch_call_back:what];
    return ;
}

@end
