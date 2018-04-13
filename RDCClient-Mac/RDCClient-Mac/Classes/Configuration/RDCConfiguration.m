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

@synthesize serverIPAddr;
@synthesize serverPort;
@synthesize localPort;
@synthesize shouldAutoAgree;
@synthesize shouldCaptureMouse;
@synthesize shouldVerifyPassword;
@synthesize shouldDeleteWallpaper;

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

-(NSString*)serverIPAddr {
    return [_configDict objectForKey:@"ServerIPAddr"];
}

-(void)setServerIPAddr:(NSString *)serverIPAddr {
    [_configDict setObject:serverIPAddr forKey:@"ServerIPAddr"];
    return ;
}

-(NSString *)serverPort {
    return [_configDict objectForKey:@"ServerPort"];
}

-(void)setServerPort:(NSString *)port {
    [_configDict setObject:port forKey:@"ServerPort"];
    return ;
}

-(NSString *)localPort {
    return [_configDict objectForKey:@"LocalPort"];
}

-(void)setLocalPort:(NSString *)localPort {
    [_configDict setObject:localPort forKey:@"LocalPort"];
    return ;
}

-(BOOL)shouldAutoAgree {
    return [[_configDict objectForKey:@"ShouldAutoAgree"] boolValue];
}

-(void)setShouldAutoAgree:(BOOL)shouldAutoAgree {
    [_configDict setObject:@(shouldAutoAgree) forKey:@"ShouldAutoAgree"];
    return ;
}

-(BOOL)shouldVerifyPassword {
    return [[_configDict objectForKey:@"ShouldVerifyPassword"] boolValue];
}

-(void)setShouldVerifyPassword:(BOOL)shouldVerifyPassword {
    [_configDict setObject:@(shouldVerifyPassword) forKey:@"ShouldVerifyPassword"];
    return ;
}

-(BOOL)shouldCaptureMouse {
    return [[_configDict objectForKey:@"ShouldCaptureMouse"] boolValue];
}

-(void)setShouldCaptureMouse:(BOOL)shouldCaptureMouse {
    [_configDict setObject:@(shouldCaptureMouse) forKey:@"ShouldCaptureMouse"];
    return ;
}

-(BOOL)shouldDeleteWallpaper {
    return [[_configDict objectForKey:@"ShouldDeleteWallpaper"] boolValue];
}

-(void)setShouldDeleteWallpaper:(BOOL)shouldDeleteWallpaper {
    [_configDict setObject:@(shouldDeleteWallpaper) forKey:@"ShouldDeleteWallpaper"];
    return ;
}

@end
