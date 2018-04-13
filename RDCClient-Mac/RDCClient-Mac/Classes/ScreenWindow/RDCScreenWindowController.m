//
//  RDCScreenWindowController.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/27.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCTcpSocket.h"
#import "RDCMessage.h"
#import "RDCMessageQueue.h"
#import "RDCUtils.h"
#import "RDCDrawingView.h"
#import "RDCConfiguration.h"
#import "RDCScreenWindowController.h"

@interface RDCScreenWindowController () <RDCTcpSocketDelegate> {
    unsigned char* oriBits;
    dispatch_semaphore_t _eventQueueSemaphore;
    dispatch_semaphore_t _msgParseSemaphore;
}

@property(nonatomic, strong) NSMutableData* comprData;  //压缩数据
@property(nonatomic, strong) NSMutableData* originData; //原数据

@property(nonatomic, assign) NSInteger comprSize;
@property(nonatomic, assign) NSInteger originSize;

@property(nonatomic, strong) RDCMessageQueue* msgQueue;
@property(nonatomic, strong) RDCMessageQueue* eventQueue;

@property(nonatomic, strong) NSThread* eventThread;
@property(nonatomic, strong) NSThread* parseThread;

@property(nonatomic, assign) CGPoint mouseLocation;
@property(nonatomic, weak) IBOutlet RDCDrawingView* imageDrawingView;

@property(nonatomic, assign) NSInteger XResolution;
@property(nonatomic, assign) NSInteger YResolution;

@end

@implementation RDCScreenWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    oriBits = NULL;
    
    _eventQueueSemaphore = dispatch_semaphore_create(1);
    _msgParseSemaphore = dispatch_semaphore_create(1);
    
    _msgQueue = [[RDCMessageQueue alloc] init];
    _eventQueue = [[RDCMessageQueue alloc] init];
    
    _comprData = [NSMutableData data];
    _originData = [NSMutableData data];
    
    //启动解析线程
    _parseThread = [[NSThread alloc] initWithTarget:self selector:@selector(parseMessage) object:nil];
    [_parseThread start];
    
    //启动事件发送线程
    _eventThread = [[NSThread alloc] initWithTarget:self selector:@selector(eventHandler) object:nil];
    [_eventThread start];
    
    return ;
}

-(void)eventHandler {
    while(_eventThread.isCancelled == NO)
    {
        dispatch_semaphore_wait(_eventQueueSemaphore, DISPATCH_TIME_FOREVER);
        
        while(_eventQueue.empty == NO) {
            RDCMessage* eventMsg = _eventQueue.pop_front;
            [_commandSocket sendMessage:eventMsg];
        }
    }
    return;
}

-(NSPoint)convertPointToScreen:(NSPoint)location {
    NSSize winSize = self.window.contentView.bounds.size;
    
    CGFloat xPosition = location.x * _XResolution / winSize.width;
    CGFloat yPosition = location.y * _YResolution / winSize.width;
    
    return NSMakePoint(xPosition, yPosition);
}

-(void)setScreenSocket:(RDCTcpSocket *)screenSocket {
    _screenSocket = screenSocket;
    _screenSocket.delegate = self;
    
    //先请求被控端屏幕分辨率
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandResolutionRequest];
    [_screenSocket sendMessage:msg];
    return ;
}

- (void)dealloc
{
    free(oriBits);
    oriBits = NULL;
}

-(void)parseMessage {
    while(_parseThread.isCancelled == NO) {
        dispatch_semaphore_wait(_msgParseSemaphore, DISPATCH_TIME_FOREVER);
        
        while(_msgQueue.empty == NO) {
            RDCMessage* msg = [_msgQueue pop_front];
            
            switch (msg.serviceCommand) {
                case ServiceCommandResolutionResponse:
                {
                    //被控端回复分辨率
                    NSString* resolution = [msg nextString:msg.size - msg.current];
                    NSArray* comp = [resolution componentsSeparatedByString:@"x"];
                    if(comp.count == 2) {
                        _XResolution = [comp[0] integerValue];
                        _YResolution = [comp[1] integerValue];
                        
                        _imageDrawingView.resolution = CGSizeMake(_XResolution, _YResolution);
                        _originSize = _XResolution * _YResolution * 4;
                        
                        //请求屏幕第一帧数据
                        RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenFirstFrame];
                        [_screenSocket sendMessage:rmsg];
                    }
                }
                    break;
                case ServiceCommandScreenData:
                {
                    BOOL bHasMouseLocation = (BOOL)msg.nextChar;
                    
                    if(bHasMouseLocation == YES) {
                        _mouseLocation.x = (CGFloat)msg.nextLongInteger / 100000;
                        _mouseLocation.y = (CGFloat)msg.nextLongInteger / 100000;
                    }
                    _comprSize = msg.nextInteger;
                    
                    [_comprData appendData:[msg.data subdataWithRange:NSMakeRange(msg.current, msg.size - msg.current)]];
                }
                    break;
                default:
                    [_comprData appendData:msg.data];
                    break;
            }
            
            if(_comprData.length == _comprSize && _comprData.length > 0 && _comprSize > 0)
            {
                NSData* uncomprData = [RDCUtils.sharedInstance uncompressData:_comprData originLength:_originSize];
                
                if(uncomprData != nil) {
                    if(_originData.length == 0) {
                        //填充alpha字节
                        @autoreleasepool {
                            const UInt8* uncompr_ptr = (const UInt8*)uncomprData.bytes;
                            UInt8* data_ptr = (UInt8*)malloc(sizeof(UInt8) * _originSize);
                            memset(data_ptr, 0, sizeof(UInt8) * _originSize);
                            
                            int idx = 0;
                            for(int i = 0; i != _originSize; ++i) {
                                if((i + 1) % 4 != 0) {
                                    *(data_ptr + i) = *(uncompr_ptr + idx);
                                    ++idx;
                                }
                                else
                                    *(data_ptr + i) = 0xFF;
                            }
                            
                            [_originData appendBytes:data_ptr length:_originSize];
                            free(data_ptr);
                        }
                    }else {
                        @autoreleasepool {
                            if(oriBits == NULL) {
                                oriBits = (unsigned char*)malloc(sizeof(unsigned char) * _originSize);
                                memset(oriBits, 0xFF, sizeof(unsigned char) * _originSize);
                            }
                            
                            const unsigned char* cmp_ptr = uncomprData.bytes;
                            const unsigned char* ori_ptr = _originData.bytes;
                            
                            int idx = 0;
                            for(int i = 0; i != _originSize; ++i) {
                                if((i + 1) % 4 != 0) {
                                    *(oriBits + i) = (*(ori_ptr + i)) ^ (*(cmp_ptr + idx));
                                    ++idx;
                                }
                            }
                            [_originData replaceBytesInRange:NSMakeRange(0, _originSize) withBytes:oriBits];
                        }
                    }
                    
                    _imageDrawingView.imageData = _originData;
                    
                    //删除原有压缩数据
                    [_comprData resetBytesInRange:NSMakeRange(0, _comprData.length)];
                    [_comprData setLength:0];
                    
                    //继续请求下一帧
                    RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenNextFrame];
                    [_screenSocket sendMessage:rmsg];
                }
            }
        }
    }
    
    return ;
}

#pragma mark - RDCTcpSocketDelegate
-(void)messageReceivedOnSocket:(RDCTcpSocket *)socket message:(RDCMessage *)message
{
    [_msgQueue push_back:message];
    dispatch_semaphore_signal(_msgParseSemaphore);
    return ;
}

@end
