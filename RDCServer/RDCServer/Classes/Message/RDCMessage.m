//
//  RDCMessage.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCMessage.h"

@interface RDCMessage()
-(instancetype)init;

@property(nonatomic, strong) NSMutableData* _data_;

@property(nonatomic, assign) NSInteger theCurrent;

@end

@implementation RDCMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        __data_ = [NSMutableData data];
        
        _theCurrent = 0;
    }
    return self;
}

+(RDCMessage *)message {
    RDCMessage* msg = [[RDCMessage alloc] init];
    return msg;
}

+(RDCMessage *)messageWithServiceCommand:(RDCServiceCommand)cmd
{
    RDCMessage* msg = [[RDCMessage alloc] init];
    [msg._data_ appendBytes:&cmd length:sizeof(unsigned int)];
    
    return msg;
}

-(void)appendChar:(unsigned char)data {
    [self._data_ appendBytes:&data length:sizeof(unsigned char)];
    
    return ;
}

-(void)appendShort:(unsigned short)data {
    [self._data_ appendBytes:&data length:sizeof(unsigned short)];
    
    return ;
}

-(void)appendInteger:(unsigned int)data {
    [self._data_ appendBytes:&data length:sizeof(unsigned int)];
    
    return ;
}

-(void)appendData:(const unsigned char *)data length:(NSInteger)length {
    [self._data_ appendBytes:data length:length];
    
    return ;
}

-(void)appendData:(NSData *)data {
    [self._data_ appendData:data];
    return ;
}

-(void)appendString:(NSString *)data {
    NSData* tmp = [data dataUsingEncoding:NSUTF8StringEncoding];
    [self._data_ appendData:tmp];
    
    return ;
}

-(unsigned char)nextChar {
    unsigned char data = 0;
    [__data_ getBytes:&data range:NSMakeRange(_theCurrent, sizeof(unsigned char))];
    _theCurrent += sizeof(unsigned char);
    
    return data;
}

-(unsigned short)nextShort {
    unsigned short data = 0;
    [__data_ getBytes:&data range:NSMakeRange(_theCurrent, sizeof(unsigned short))];
    _theCurrent += sizeof(unsigned short);
    
    return data;
}

-(unsigned int)nextInteger {
    unsigned int data = 0;
    [__data_ getBytes:&data range:NSMakeRange(_theCurrent, sizeof(unsigned int))];
    _theCurrent += sizeof(unsigned int);
    
    return data;
}

-(NSData *)nextData:(NSInteger)length {
    NSData* tmp = [__data_ subdataWithRange:NSMakeRange(_theCurrent, length)];
    _theCurrent += tmp.length;
    
    return tmp;
}

-(NSString *)nextString:(NSInteger)length {
    NSData* tmp = [self nextData:length];
    return [[NSString alloc] initWithData:tmp encoding:NSUTF8StringEncoding];
}

-(RDCServiceCommand)serviceCommand {
    return (RDCServiceCommand)self.nextInteger;
}

-(void)clear {
    [__data_ resetBytesInRange:NSMakeRange(0, __data_.length)];
    [__data_ setLength:0];
    
    return ;
}

-(void)reset {
    _theCurrent = 0;
    return ;
}

-(NSInteger)size {
    return __data_.length;
}

-(NSInteger)current {
    return _theCurrent;
}

-(NSData *)data {
    return __data_;
}

@end
