//
//  RDCConfiguration.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCConfiguration.h"

@interface RDCConfiguration()

@property(nonatomic, strong) NSMutableDictionary* configDict;

@end

static RDCConfiguration* config = nil;
@implementation RDCConfiguration
@synthesize serverPort;

- (instancetype)init
{
    if(config != nil)
        @throw @"请使用+standardConfiguration单例";
    
    self = [super init];
    if (self) {
        _configDict = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RDCConfiguration" ofType:@"plist"]];
    }
    return self;
}

+(instancetype)standardConfiguration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[RDCConfiguration alloc] init];
    });
    
    return config;
}

-(BOOL)saveConfiguration {
    return [_configDict writeToFile:[[NSBundle mainBundle] pathForResource:@"RDCConfiguration" ofType:@"plist"] atomically:NO];
}

-(NSString *)serverPort {
    return [_configDict objectForKey:@"Port"];
}

-(void)setServerPort:(NSString *)port {
    [_configDict setObject:port forKey:@"Port"];
    return ;
}

@end
