//
//  RDCConfiguration.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@interface RDCConfiguration : NSObject

+(instancetype)standardConfiguration;

@property(nonatomic, copy) NSString* serverIPAddr;
@property(nonatomic, copy) NSString* serverPort;
@property(nonatomic, copy) NSString* localPort;
@property(nonatomic, assign) BOOL shouldAutoAgree;
@property(nonatomic, assign) BOOL shouldVerifyPassword;
@property(nonatomic, assign) BOOL shouldDeleteWallpaper;
@property(nonatomic, assign) BOOL shouldCaptureMouse;

-(BOOL)saveConfiguration;

@end
