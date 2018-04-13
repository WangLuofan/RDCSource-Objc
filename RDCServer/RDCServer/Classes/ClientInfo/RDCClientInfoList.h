//
//  RDCClientInfoList.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDCClientInfo;
@class RDCTcpSocket;
@interface RDCClientInfoList : NSObject

+(instancetype)sharedInstance;

-(void)appendClientInfo:(RDCClientInfo*)cliInfo;

-(RDCClientInfo*)clientInfoAtIndex:(NSInteger)index;
-(RDCClientInfo*)clientInfoWithToken:(NSString*)token;
-(RDCClientInfo*)clientInfoWithSocket:(RDCTcpSocket*)socket;

-(void)clear;
-(void)removeClientInfoAtIndex:(NSInteger)index;
-(void)removeClientInfo:(RDCClientInfo*)cliInfo;

-(NSInteger)count;

@end
