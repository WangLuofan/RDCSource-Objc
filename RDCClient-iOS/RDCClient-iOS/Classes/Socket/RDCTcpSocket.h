//
//  RDCTcpSocket.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCTcpSocketInterface.h"

@interface RDCTcpSocket : NSObject <RDCTcpSocketDelegate>

-(instancetype)initSocketCreate;
-(instancetype)initWithFileDescriptor:(int)fileDescriptor;

//Socket 描述符
@property(nonatomic, assign) int fileDescriptor;
@property(nonatomic, assign) id<RDCTcpSocketDelegate> delegate;

-(void)sendMessage:(RDCMessage*)msg;
-(void)sendMessage:(const void*)msg length:(NSInteger)length;

-(void)receiveMessage;

-(void)connectToHost:(NSString*)host Port:(unsigned short)port;
-(void)connectToHost:(RDCHostInfo*)hostInfo;

-(void)shutdown;

@end
