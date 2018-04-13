//
//  RDCHostInfo.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
@interface RDCHostInfo : NSObject

-(instancetype)initWithIPAddr:(NSString*)ipaddr port:(NSInteger)port host:(NSString*)host;
-(instancetype)initWithAddr:(struct sockaddr_in)addr;

@property(nonatomic, copy) NSString* ipAddress;
@property(nonatomic, copy) NSString* port;
@property(nonatomic, copy) NSString* hostName;

-(struct sockaddr_in)toNative;

@end
