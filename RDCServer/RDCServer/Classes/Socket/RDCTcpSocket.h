//
//  RDCTcpSocket.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCTcpSocketInterface.h"

@interface RDCTcpSocket : NSObject <RDCTcpSocketDelegate>

-(instancetype)initWithFileDescriptor:(NSInteger)fileDescriptor;

//Socket 描述符
@property(nonatomic, assign) NSInteger fileDescriptor;
@property(nonatomic, assign) id<RDCTcpSocketDelegate> delegate;

-(void)sendMessage:(RDCMessage*)msg;
-(void)listenAtPort:(NSInteger)port;

-(void)connectToHost:(NSString*)host Port:(unsigned short)port;
-(void)connectToHost:(RDCHostInfo*)hostInfo;

-(void)shutdown;
-(void)close;

@end
