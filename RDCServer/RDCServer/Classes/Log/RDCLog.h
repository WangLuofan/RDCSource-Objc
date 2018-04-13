//
//  RDCLog.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@interface RDCLog : NSObject

//时间
@property(nonatomic, copy) NSString* timeStamp;
//内容
@property(nonatomic, copy) NSString* content;

@end

@interface RDCLogList : NSObject

+(instancetype)sharedInstance;

-(NSInteger)count;
-(RDCLog*)logAtIndex:(NSInteger)index;
-(void)writeLog:(NSString*)content;
-(void)clear;

@end
