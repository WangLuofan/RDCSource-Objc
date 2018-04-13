//
//  RDCUtils.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCCocoaKeycodes.h"
@interface RDCUtils : NSObject

+(instancetype)sharedInstance;
-(NSString*)currentTimeStamp;
-(NSString*)prettySystemVersionDescription;
-(NSString*)hostName;
-(NSData*)compressData:(NSData*)data;
-(NSData*)compressData:(const u_char*)data length:(NSInteger)length;
-(NSData*)uncompressData:(NSData*)data originLength:(NSInteger)oriLen;
-(NSInteger)VirutalKeyCodeFromString:(NSString*)keyString;
-(NSArray<NSString*>*)VirtualKeyStringFromCode:(NSInteger)keyCode;

@end
