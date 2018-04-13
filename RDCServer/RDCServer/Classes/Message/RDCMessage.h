//
//  RDCMessage.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@interface RDCMessage : NSObject

+(RDCMessage*)message;
+(RDCMessage*)messageWithServiceCommand:(RDCServiceCommand)cmd;

-(RDCServiceCommand)serviceCommand;

-(unsigned char)nextChar;
-(unsigned short)nextShort;
-(unsigned int)nextInteger;
-(NSData*)nextData:(NSInteger)length;
-(NSString*)nextString:(NSInteger)length;

-(void)appendChar:(unsigned char)data;
-(void)appendShort:(unsigned short)data;
-(void)appendInteger:(unsigned int)data;
-(void)appendData:(NSData*)data;
-(void)appendData:(const unsigned char*)data length:(NSInteger)length;
-(void)appendString:(NSString*)data;

-(void)clear;
-(NSInteger)size;
-(void)reset;
-(NSData*)data;
-(NSInteger)current;

@end
