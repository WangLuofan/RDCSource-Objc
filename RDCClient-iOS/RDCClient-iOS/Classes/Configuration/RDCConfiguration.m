//
//  RDCConfiguration.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCConfiguration.h"

@implementation RDCConfiguration

@dynamic serverAddr;
@dynamic serverPort;

+(NSString*)serverAddr {
    NSString* addr = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerAddr"];
    if(addr == nil) {
        addr = @"127.0.0.1";
        [[NSUserDefaults standardUserDefaults] setObject:addr forKey:@"ServerAddr"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return addr;
}

+(void)setServerAddr:(NSString*)serverAddr {
    [[NSUserDefaults standardUserDefaults] setObject:serverAddr forKey:@"ServerAddr"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return ;
}

+(NSUInteger)serverPort {
    NSString* port = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerPort"];
    if(port == nil) {
        port = @"9999";
        
        [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"ServerPort"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return port.integerValue;
}

+(void)setServerPort:(NSUInteger)serverPort {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%lu", (unsigned long)serverPort] forKey:@"ServerPort"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return ;
}

@end
