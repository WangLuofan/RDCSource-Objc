//
//  RDCClientInfo.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@class RDCTcpSocket;
@class RDCHostInfo;

typedef NS_ENUM(NSUInteger, RDCClientStatus)
{
    ClientStatusOnline,                         //客户端在线
    ClientStatusOffline,                        //客户端离线
};

@interface RDCClientInfo : NSObject

//客户端套接字
@property(nonatomic, strong) RDCTcpSocket* clientSocket;
//主/被控端信息
@property(nonatomic, weak) RDCClientInfo* peerClientInfo;
//客户端信息
@property(nonatomic, strong) RDCHostInfo* clientHostInfo;
//系统版本
@property(nonatomic, copy) NSString* clientSystemVersion;
//Token
@property(nonatomic, copy) NSString* clientToken;
//Password
@property(nonatomic, copy) NSString* clientPassword;
//当前状态
@property(nonatomic, assign) RDCClientStatus clientStatus;
//时间戳
@property(nonatomic, copy) NSString* onlineTimeStamp;
//状态描述词
@property(nonatomic, copy) NSString* clientStatusDescription;

@end
