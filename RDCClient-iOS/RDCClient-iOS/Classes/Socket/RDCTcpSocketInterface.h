//
//  RDCTcpSocketInterface.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#ifndef RDCTcpSocketInterface_h
#define RDCTcpSocketInterface_h

@class RDCTcpSocket;
@class RDCHostInfo;
@class RDCMessage;
@protocol RDCTcpSocketDelegate <NSObject>

@optional
-(void)errorOccuredOnSocket:(RDCTcpSocket*)socket desc:(NSString*)desc;
-(void)clientConnectedWithOnNewSocket:(RDCTcpSocket*)newSocket addr:(RDCHostInfo*)addr;
-(void)connectedToServerOnSocket:(RDCTcpSocket*)socket;
-(void)clientDisconnectedOnSocket:(RDCTcpSocket*)socket;
-(void)timeOutEventOccuredOnSocket:(RDCTcpSocket*)socket;
-(void)messageReceivedOnSocket:(RDCTcpSocket*)socket message:(RDCMessage*)message;

@end

#endif /* RDCTcpSocketInterface_h */
