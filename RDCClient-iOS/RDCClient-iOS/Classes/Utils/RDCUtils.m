//
//  RDCUtils.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"

#import <zlib.h>
#import <ImageIO/ImageIO.h>

#define SEQ(str1, str2) [str1 compare:str2 options:NSCaseInsensitiveSearch] == NSOrderedSame

static RDCUtils* _obj = nil;
@implementation RDCUtils

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _obj = [[RDCUtils alloc] init];
    });
    return _obj;
}

-(NSString *)currentTimeStamp {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    
    return [formatter stringFromDate:[NSDate date]];
}
-(NSString *)hostName {
    return [NSProcessInfo processInfo].hostName;
}

-(NSString *)prettySystemVersionDescription {
    NSProcessInfo* processInfo = [NSProcessInfo processInfo];
    NSOperatingSystemVersion version = [processInfo operatingSystemVersion];
    return [NSString stringWithFormat:@"iOS %ld.%ld.%ld", (long)version.majorVersion,(long)version.minorVersion, (long)version.patchVersion];
}

-(NSData *)compressData:(NSData *)data {
    NSData* tmpData = nil;
    
    @autoreleasepool {
        uLong bounds = compressBound(data.length);
        
        u_char* comprData = (u_char*)malloc(sizeof(u_char) * bounds);
        bzero(comprData, sizeof(u_char) * bounds);
        
        if(compress(comprData, &bounds, (const Bytef*)data.bytes, data.length) == Z_OK) {
            tmpData = [NSData dataWithBytesNoCopy:comprData length:bounds freeWhenDone:YES];
        }
    }
    
    return tmpData;
}

-(NSData*)compressData:(const u_char *)data length:(NSInteger)length {
    NSData* comprDat = [NSData dataWithBytes:data length:length];
    if(comprDat != nil)
        return [self compressData:comprDat];
    return nil;
}

-(NSData *)uncompressData:(NSData *)data originLength:(NSInteger)oriLen
{
    NSData* tmpData = nil;
    
    @autoreleasepool {
        uLong uncomprLen = oriLen;
        u_char* uncomprData = (u_char*)malloc(sizeof(unsigned char) * uncomprLen);
        bzero(uncomprData, sizeof(unsigned char) * uncomprLen);
        
        int result = uncompress(uncomprData, &uncomprLen, (const Bytef*)data.bytes, data.length);
        if(result == Z_OK) {
            tmpData = [NSData dataWithBytes:uncomprData length:uncomprLen];
        }
        
        free(uncomprData);
    }
    return tmpData;
}

-(NSInteger)VirutalKeyCodeFromString:(NSString *)keyString {
#define KSEQ(str) SEQ(keyString, [NSString stringWithUTF8String:str])
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("F"))
        return kVK_ANSI_F;
    if(KSEQ("H"))
        return kVK_ANSI_H;
    if(KSEQ("G"))
        return kVK_ANSI_G;
    if(KSEQ("Z"))
        return kVK_ANSI_Z;
    if(KSEQ("X"))
        return kVK_ANSI_X;
    if(KSEQ("C"))
        return kVK_ANSI_C;
    if(KSEQ("V"))
        return kVK_ANSI_V;
    if(KSEQ("B"))
        return kVK_ANSI_B;
    if(KSEQ("Q"))
        return kVK_ANSI_Q;
    if(KSEQ("W"))
        return kVK_ANSI_W;
    if(KSEQ("E"))
        return kVK_ANSI_E;
    if(KSEQ("R"))
        return kVK_ANSI_R;
    if(KSEQ("Y"))
        return kVK_ANSI_Y;
    if(KSEQ("T"))
        return kVK_ANSI_T;
    if(KSEQ("O"))
        return kVK_ANSI_O;
    if(KSEQ("U"))
        return kVK_ANSI_U;
    if(KSEQ("I"))
        return kVK_ANSI_I;
    if(KSEQ("P"))
        return kVK_ANSI_P;
    if(KSEQ("L"))
        return kVK_ANSI_L;
    if(KSEQ("J"))
        return kVK_ANSI_J;
    if(KSEQ("K"))
        return kVK_ANSI_K;
    if(KSEQ("N"))
        return kVK_ANSI_N;
    if(KSEQ("M"))
        return kVK_ANSI_M;
    if(KSEQ("0") || KSEQ(")"))
        return kVK_ANSI_0;
    if(KSEQ("1") || KSEQ("!"))
        return kVK_ANSI_1;
    if(KSEQ("2") || KSEQ("@"))
        return kVK_ANSI_2;
    if(KSEQ("3") || KSEQ("#"))
        return kVK_ANSI_3;
    if(KSEQ("4") || KSEQ("$"))
        return kVK_ANSI_4;
    if(KSEQ("5") || KSEQ("%"))
        return kVK_ANSI_5;
    if(KSEQ("6") || KSEQ("^"))
        return kVK_ANSI_6;
    if(KSEQ("7") || KSEQ("&"))
        return kVK_ANSI_7;
    if(KSEQ("8") || KSEQ("*"))
        return kVK_ANSI_8;
    if(KSEQ("9") || KSEQ("("))
        return kVK_ANSI_9;
    if(KSEQ("F1"))
        return kVK_F1;
    if(KSEQ("F2"))
        return kVK_F2;
    if(KSEQ("F3"))
        return kVK_F3;
    if(KSEQ("F4"))
        return kVK_F4;
    if(KSEQ("F5"))
        return kVK_F5;
    if(KSEQ("F6"))
        return kVK_F6;
    if(KSEQ("F7"))
        return kVK_F7;
    if(KSEQ("F8"))
        return kVK_F8;
    if(KSEQ("F9"))
        return kVK_F9;
    if(KSEQ("F10"))
        return kVK_F10;
    if(KSEQ("F11"))
        return kVK_F11;
    if(KSEQ("F12"))
        return kVK_F12;
    if(KSEQ("Esc"))
        return kVK_Escape;
    if(KSEQ("Tab"))
        return kVK_Tab;
    if(KSEQ(" "))
        return kVK_Space;
    if(KSEQ("CMD"))
        return kVK_Command;
    if(KSEQ("SHFT"))
        return kVK_Shift;
    if(KSEQ("RSHFT"))
        return kVK_RightShift;
    if(KSEQ("CAPLK"))
        return kVK_CapsLock;
    if(KSEQ("Home"))
        return kVK_Home;
    if(KSEQ("PgUp"))
        return kVK_PageUp;
    if(KSEQ("PgDn"))
        return kVK_PageDown;
    if(KSEQ("End"))
        return kVK_End;
    if(KSEQ("ALT"))
        return kVK_Option;
    if(KSEQ("RALT"))
        return kVK_RightOption;
    if(KSEQ("CTRL"))
        return kVK_Control;
    if(KSEQ("RCTL"))
        return kVK_RightControl;
    if(KSEQ("FN"))
        return kVK_Function;
    if(KSEQ("VUP"))
        return kVK_VolumeUp;
    if(KSEQ("VDON"))
        return kVK_VolumeDown;
    if(KSEQ("MUTE"))
        return kVK_Mute;
    if(KSEQ("Up"))
        return kVK_UpArrow;
    if(KSEQ("Down"))
        return kVK_DownArrow;
    if(KSEQ("Left"))
        return kVK_LeftArrow;
    if(KSEQ("Right"))
        return kVK_RightArrow;
    if(KSEQ("Del"))
        return kVK_Delete;
    if(KSEQ("FDEL"))
        return kVK_ForwardDelete;
    if(KSEQ("-") || KSEQ("_"))
        return kVK_ANSI_Minus;
    if(KSEQ("+") || KSEQ("="))
        return kVK_ANSI_Equal;
    if(KSEQ("/") || KSEQ("?"))
        return kVK_ANSI_Slash;
    if(KSEQ(",") || KSEQ("<"))
        return kVK_ANSI_Comma;
    if(KSEQ(":") || KSEQ(";"))
        return kVK_ANSI_Semicolon;
    if(KSEQ("\\") || KSEQ("|"))
        return kVK_ANSI_Backslash;
    if(KSEQ("]") || KSEQ("}"))
        return kVK_ANSI_RightBracket;
    if(KSEQ("[") || KSEQ("{"))
        return kVK_ANSI_LeftBracket;
    if(KSEQ("RET"))
        return kVK_Return;
    if(KSEQ("`") || KSEQ("~"))
        return kVK_ANSI_Grave;
    if(KSEQ(".") || KSEQ(">"))
        return kVK_ANSI_Period;
    if(KSEQ("'") || KSEQ("\""))
        return kVK_ANSI_Quote;
    return -1;
}

-(NSArray<NSString *> *)VirtualKeyStringFromCode:(NSInteger)keyCode
{
    return nil;
}

@end
