//
//  RDCServer.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCLog.h"
#import "RDCTcpSocket.h"
#import "RDCServer.h"
#import "RDCHostInfo.h"
#import "RDCConfiguration.h"
#import "RDCClientInfo.h"
#import "RDCMessage.h"
#import "RDCUtils.h"
#import "RDCClientInfoList.h"

@interface RDCServer() <RDCTcpSocketDelegate>

@property(nonatomic, strong) RDCTcpSocket* serverSocket;
@property(nonatomic, strong) NSThread* serverThread;

@end

@implementation RDCServer

-(void)startListening {
    if(_serverSocket == nil) {
        _serverSocket = [[RDCTcpSocket alloc] init];
        _serverSocket.delegate = self;
    }
    
    //启动端口监听
    [_serverSocket listenAtPort:RDCConfiguration.standardConfiguration.serverPort.integerValue];
    return ;
}

-(void)start {
    _serverThread = [[NSThread alloc] initWithTarget:self selector:@selector(startListening) object:nil];
    [_serverThread start];
    return ;
}

-(void)exit {
    //退出线程
    [_serverSocket close];
    [_serverThread cancel];
    return ;
}

#pragma mark - RDCTcpSocketDelegate
-(void)clientConnectedWithOnNewSocket:(RDCTcpSocket *)newSocket addr:(RDCHostInfo *)addr
{
    //客户端上线，添加数据
    RDCClientInfo* cliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:newSocket];
    if(cliInfo == nil) {
        cliInfo = [[RDCClientInfo alloc] init];
        [RDCClientInfoList.sharedInstance appendClientInfo:cliInfo];
    }
    
    newSocket.delegate = self;
    cliInfo.clientSocket = newSocket;
    cliInfo.clientHostInfo = addr;
    
    return ;
}

-(void)clientDisconnectedOnSocket:(RDCTcpSocket *)socket {
    RDCClientInfo* cliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];
    if(cliInfo != nil) {
        //写入日志
//        WriteLog(@"%@ 已断开与服务端的连接", cliInfo.clientHostInfo.hostName);
        [RDCClientInfoList.sharedInstance removeClientInfo:cliInfo];
        [RDCNotificationCenter postNotificationName:kMainTableViewShouldReloadNotification object:nil];
    }
    return ;
}

-(void)messageReceivedOnSocket:(RDCTcpSocket *)socket message:(RDCMessage *)message
{
    switch(message.serviceCommand) {
        case ServiceCommandSYN:
        {
            //上线
            RDCClientInfo* cliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];
            if(cliInfo != nil)
            {
                //拿出主机名称
                int hostLen = message.nextChar;
                NSString* hostName = [message nextString:hostLen];
                
                int sysLen = message.nextChar;
                NSString* sysVer = [message nextString:sysLen];
                
                //填写主机名， 系统版本， 上线时间等信息
                cliInfo.clientHostInfo.hostName = hostName;
                cliInfo.clientSystemVersion = sysVer;
                cliInfo.onlineTimeStamp = [RDCUtils currentTimeStamp];
                
                //随机生成Token 及 Password
                cliInfo.clientToken = [NSString stringWithFormat:@"%06d", (arc4random() % 1000000)];
                cliInfo.clientPassword = [NSString stringWithFormat:@"%08d", (arc4random() % 100000000)];
                cliInfo.clientStatus = ClientStatusOnline;
                
                //通知主线程更新UI
                [RDCNotificationCenter postNotificationName:kMainTableViewShouldReloadNotification object:nil];
                
                //写入日志
//                WriteLog(@"%@ 已经成功连接到服务器", hostName);
                
                //回复ACK、Token及Password
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandACK];
                [rmsg appendChar:cliInfo.clientToken.length];
                [rmsg appendString:cliInfo.clientToken];
                [rmsg appendChar:cliInfo.clientPassword.length];
                [rmsg appendString:cliInfo.clientPassword];
                
                [socket sendMessage:rmsg];
            }
        }
            break;
        case ServiceCommandConnectionDenied:
        {
            RDCClientInfo* myInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];    //被控端
            RDCClientInfo* cliInfo = myInfo.peerClientInfo;
            
            if(cliInfo != nil) {
                //转发消息给对面
                [cliInfo.clientSocket sendMessage:message];
                //解除绑定信息
                myInfo.peerClientInfo = nil;
                cliInfo.peerClientInfo = nil;
            }
        }
            break;
        case ServiceCommandConnectionQuery:
        {
            //主控端请求连接
            int tokLen = message.nextChar;
            NSString* token = [message nextString:tokLen];
            
            RDCMessage* rmsg = nil;
            
            RDCClientInfo* myInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];    //主控端
            RDCClientInfo* cliInfo = [RDCClientInfoList.sharedInstance clientInfoWithToken:token];
            if(cliInfo == nil)
            {
                //未注册的Token
                rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandTokenNotFound];
                [socket sendMessage:rmsg];
            }
            else if(cliInfo.peerClientInfo != nil)
            {
                //如果已经有对端信息，说明被控端已有连接，返回错误
            }
            else
            {
                //双方建立关系
                myInfo.peerClientInfo = cliInfo;
                cliInfo.peerClientInfo = myInfo;
                
                //添加地址信息, 转发给被控端
                rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionQuery];
                NSString* hostInfo = [NSString stringWithFormat:@"%@(%@)", myInfo.clientHostInfo.hostName, myInfo.clientHostInfo.ipAddress];
                [rmsg appendChar:hostInfo.length];
                [rmsg appendString:hostInfo];
                [cliInfo.clientSocket sendMessage:rmsg];
            }
        }
            break;
        case ServiceCommandVerifyRequest:
        {
            BOOL bShouldVerifyPassword = (BOOL)message.nextChar;
            if(bShouldVerifyPassword == YES) {
                RDCClientInfo* myCliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];
                
                if(myCliInfo.peerClientInfo != nil)
                {
                    RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyRequest];
                    [rmsg appendChar:myCliInfo.clientPassword.length];
                    [rmsg appendString:myCliInfo.clientPassword];
                    
                    //下发验证密码给主控端进行验证
                    [myCliInfo.peerClientInfo.clientSocket sendMessage:rmsg];
                }
            }else {
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyComplete];
                [socket sendMessage:rmsg];
            }
        }
            break;
        case ServiceCommandVerifyComplete:
        case ServiceCommandVerifyFailed:
        {
            RDCClientInfo* myCliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket]; //主控端
            
            //发送消息给被控端
            if(myCliInfo.peerClientInfo != nil)
                [myCliInfo.peerClientInfo.clientSocket sendMessage:message];
            
            //重置指针
            [message reset];
            if(message.serviceCommand == ServiceCommandVerifyFailed)
            {
                //验证失败，取消双方关系
                RDCClientInfo* peerInfo = myCliInfo.peerClientInfo;
                
                myCliInfo.peerClientInfo = nil;
                peerInfo.peerClientInfo = nil;
            }
        }
            break;
        case ServiceCommandConnectionReady:
        {
            //被控端已准备好连接，主控端可以连接到被控端
            RDCClientInfo* myCliInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket]; //被控端
            
            if(myCliInfo.peerClientInfo != nil)
            {
                //追加被控端IP地址
                NSString* ipaddr = myCliInfo.clientHostInfo.ipAddress;
                [message appendChar:ipaddr.length];
                [message appendString:ipaddr];
                
                [myCliInfo.peerClientInfo.clientSocket sendMessage:message];
            }
        }
            break;
        case ServiceCommandConnectionCloseSYN:
        {
            //连接准备关闭, 通知对方关闭连接
            RDCClientInfo* myInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];
            [myInfo.peerClientInfo.clientSocket sendMessage:message];
        }
            break;
        case ServiceCommandConnectionCloseACK:
        {
            //连接已经关闭，断开对端信息
            RDCClientInfo* myInfo = [RDCClientInfoList.sharedInstance clientInfoWithSocket:socket];
            RDCClientInfo* peerInfo = myInfo.peerClientInfo;
            
            peerInfo.peerClientInfo = nil;
            myInfo.peerClientInfo = nil;
            
            //转发给对面
            [peerInfo.clientSocket sendMessage:message];
        }
            break;
        default:
            break;
    }
    return ;
}

@end
