//
//  RDCMessageQueue.h
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/28.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDCMessage;
@interface RDCMessageQueue : NSObject

-(NSInteger)count;
-(void)push_back:(RDCMessage*)msg;
-(RDCMessage*)pop_front;
-(void)clear;
-(BOOL)empty;

@end
