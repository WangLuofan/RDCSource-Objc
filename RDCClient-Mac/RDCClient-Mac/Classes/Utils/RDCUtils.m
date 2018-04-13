//
//  RDCUtils.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCCocoaKeycodes.h"
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

-(void)showAlertWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void (^)(NSModalResponse))completion
{
    NSAlert* alert = [[NSAlert alloc] init];
    
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = style;
    
    for (NSString* tlt in buttons)
        [alert addButtonWithTitle:tlt];
    
    NSModalResponse result = [alert runModal];
    
    if(completion != nil)
        completion(result);
    return ;
}

-(void)beginSheetAlertForWindow:(NSWindow *)window title:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style buttons:(NSArray<NSString *> *)buttons completion:(void (^)(NSModalResponse))completion
{
    NSAlert* alert = [[NSAlert alloc] init];
    
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = style;
    
    for (NSString* tlt in buttons)
        [alert addButtonWithTitle:tlt];
    return [alert beginSheetModalForWindow:window completionHandler:completion];
}

-(void)beginTextInputSheetForWindow:(NSWindow *)window title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons placeholders:(NSArray<NSString *> *)placeholders completion:(void (^)(NSModalResponse, NSArray<NSString *> *))completion
{
    NSAlert* alert = [[NSAlert alloc] init];
    
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleInformational;
    
    for (NSString* tlt in buttons)
        [alert addButtonWithTitle:tlt];
    
    const NSInteger textFieldHeight = 22;
    const NSInteger textFieldSpacing = 5;
    
    NSView* accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, placeholders.count * textFieldHeight + (placeholders.count - 1) * textFieldSpacing)];
    
    for(int i = 0; i != placeholders.count; ++i) {
        NSTextField* textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, i * (textFieldHeight + textFieldSpacing), accessoryView.frame.size.width, textFieldHeight)];
        textField.placeholderString = [placeholders objectAtIndex:i];
        [accessoryView addSubview:textField];
    }
    alert.accessoryView = accessoryView;
    
    return [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        NSMutableArray* texts = [NSMutableArray array];
        
        for (NSTextField* textField in alert.accessoryView.subviews)
            [texts addObject:textField.objectValue];
        if(completion)
            completion(returnCode, texts);
    }];
}

-(NSData*)grabScreen {
    NSData* imgData = nil;
    @autoreleasepool {
        NSInteger screenWidth = [NSScreen mainScreen].frame.size.width;
        NSInteger screenHeight = [NSScreen mainScreen].frame.size.height;
        
        CGImageRef snapShot = CGWindowListCreateImage(NSRectToCGRect([NSScreen mainScreen].frame), kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault | kCGWindowImageBestResolution);
        
        if(CGImageGetWidth(snapShot) != screenWidth || CGImageGetHeight(snapShot) != screenHeight) {
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            CGBitmapInfo bmpInfo = CGImageGetBitmapInfo(snapShot);
            
            NSInteger width = [self xResolution].integerValue;
            NSInteger height = [self yResolution].integerValue;
            
            CGContextRef theCtx = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, bmpInfo);
            CGContextDrawImage(theCtx, CGRectMake(0, 0, width, height), snapShot);
            CGImageRelease(snapShot);
            CGImageRef scaledImage = CGBitmapContextCreateImage(theCtx);
            CGContextRelease(theCtx);
            
            CGDataProviderRef dataProvider = CGImageGetDataProvider(scaledImage);
            CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
            
            //去除alpha信息
            NSInteger bytes_length = width * 3 * height, img_length = width * 4 * height;
            UInt8* buff = (UInt8*)malloc(sizeof(UInt8) * bytes_length);
            memset(buff, 0, sizeof(UInt8) * bytes_length);
            
            const UInt8* img_ptr = CFDataGetBytePtr(tmpData);
            
            int idx = 0;
            for(int i = 0; i != img_length; ++i) {
                if((i + 1) % 4 != 0) {
                    *(buff + idx) = *(img_ptr + i);
                    ++idx;
                }
            }
            imgData = [NSData dataWithBytes:buff length:bytes_length];
            free(buff);
            
            CFRelease(tmpData);
            CGImageRelease(scaledImage);
            CGColorSpaceRelease(colorSpace);
        }
    }
    return imgData;
}

-(NSString *)xResolution {
    return [NSString stringWithFormat:@"%ld", (NSInteger)[NSScreen mainScreen].frame.size.width];
}

-(NSString *)yResolution {
    return [NSString stringWithFormat:@"%ld", (NSInteger)[NSScreen mainScreen].frame.size.height];
}

-(NSString *)hostName {
    return [NSProcessInfo processInfo].hostName;
}

-(void)removeWallpaper:(BOOL)bRemove {
    if(bRemove) {
        NSURL* fileURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];
        //保存原桌面图片
        [RDCUserDefaults setURL:fileURL forKey:@"PreviousDesktopImageURL"];
        [RDCUserDefaults synchronize];
        //修改桌面图片为纯色图
        NSURL* newBg = [[NSBundle mainBundle] URLForResource:@"Solid_Aqua_Blue" withExtension:@"png"];
        
        if(newBg != nil) {
            NSError* error = nil;
            BOOL bSuccess = [[NSWorkspace sharedWorkspace] setDesktopImageURL:newBg forScreen:[NSScreen mainScreen] options:@{                                                                      NSWorkspaceDesktopImageAllowClippingKey : @(NO), NSWorkspaceDesktopImageScalingKey: @(NSImageScaleAxesIndependently)} error:&error];
            if(bSuccess == NO && error != nil) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
                return ;
            }
        }
    }else {
        NSURL* fileURL = [RDCUserDefaults URLForKey:@"PreviousDesktopImageURL"];
        if(fileURL != nil) {
            NSError* error = nil;
            BOOL bSuccess = [[NSWorkspace sharedWorkspace] setDesktopImageURL:fileURL forScreen:[NSScreen mainScreen] options:@{                                                                      NSWorkspaceDesktopImageAllowClippingKey : @(NO), NSWorkspaceDesktopImageScalingKey: @(NSImageScaleAxesIndependently)} error:&error];
            if(bSuccess == NO && error != nil) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
                return ;
            }
        }
        
        [RDCUserDefaults removeObjectForKey:@"PreviousDesktopImageURL"];
        [RDCUserDefaults synchronize];
    }
    return ;
}

-(NSString *)prettySystemVersionDescription {
    NSProcessInfo* processInfo = [NSProcessInfo processInfo];
    
    NSOperatingSystemVersion version = [processInfo operatingSystemVersion];
    
    NSString* systemName = nil;
    switch (version.minorVersion) {
        case 0:
            systemName = @"Mac OS X Cheetah";
            break;
        case 1:
            systemName = @"Mac OS X Puma";
            break;
        case 2:
            systemName = @"Mac OS X Jaguar";
            break;
        case 3:
            systemName = @"Mac OS X Panther";
            break;
        case 4:
            systemName = @"Mac OS X Tiger";
            break;
        case 5:
            systemName = @"Mac OS X Leopard";
            break;
        case 6:
            systemName = @"Mac OS X Snow Leopard";
            break;
        case 7:
            systemName = @"OS X Lion";
            break;
        case 8:
            systemName = @"OS X Mountain Lion";
            break;
        case 9:
            systemName = @"OS X Mavericks";
            break;
        case 10:
            systemName = @"OS X Yosemite";
            break;
        case 11:
            systemName = @"OS X El Capitan";
            break;
        case 12:
            systemName = @"MacOS Sierra";
            break;
        case 13:
            systemName = @"MacOS High Sierra";
            break;
        default:
            systemName = @"MacOS Unknown_Name";
            break;
    }
    
    return [NSString stringWithFormat:@"%@(%ld.%ld.%ld)", systemName, (long)version.majorVersion,(long)version.minorVersion, (long)version.patchVersion];
}

-(NSData *)compressData:(NSData *)data {
    uLong bounds = compressBound(data.length);
    
    u_char* comprData = (u_char*)malloc(sizeof(u_char) * bounds);
    bzero(comprData, sizeof(u_char) * bounds);
    
    NSData* tmpData = nil;
    if(compress(comprData, &bounds, (const Bytef*)data.bytes, data.length) == Z_OK) {
        tmpData = [NSData dataWithBytesNoCopy:comprData length:bounds freeWhenDone:YES];
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

-(KeyboardModifiers)modifiersFromNSEventModifierFlags:(NSEventModifierFlags)flags
{
    KeyboardModifiers modifier = KeyboardModifiersMask;
    if(flags & NSEventModifierFlagCapsLock)
        modifier |= KeyboardModifiersCapsLock;
    if(flags & NSEventModifierFlagShift)
        modifier |= KeyboardModifiersShift;
    if(flags & NSEventModifierFlagControl)
        modifier |= KeyboardModifiersControl;
    if(flags & NSEventModifierFlagOption)
        modifier |= KeyboardModifiersOption;
    if(flags & NSEventModifierFlagCommand)
        modifier |= KeyboardModifiersCommand;
    if(flags & NSEventModifierFlagNumericPad)
        modifier |= KeyboardModifiersNumericPad;
    if(flags & NSEventModifierFlagHelp)
        modifier |= KeyboardModifiersHelp;
    if(flags & NSEventModifierFlagFunction)
        modifier |= KeyboardModifiersFunction;
    
    return modifier;
}

-(NSEventModifierFlags)modifiersFromKeyboardModifiers:(KeyboardModifiers)flags
{
    NSEventModifierFlags modifiers = NSDeviceIndependentModifierFlagsMask;
    if(flags & KeyboardModifiersCapsLock)
        modifiers |= NSEventModifierFlagCapsLock;
    if(flags & KeyboardModifiersShift)
        modifiers |= NSEventModifierFlagShift;
    if(flags & KeyboardModifiersControl)
        modifiers |= NSEventModifierFlagControl;
    if(flags & KeyboardModifiersOption)
        modifiers |= NSEventModifierFlagOption;
    if(flags & KeyboardModifiersCommand)
        modifiers |= NSEventModifierFlagCommand;
    if(flags & KeyboardModifiersNumericPad)
        modifiers |= NSEventModifierFlagNumericPad;
    if(flags & KeyboardModifiersHelp)
        modifiers |= NSEventModifierFlagHelp;
    if(flags & KeyboardModifiersFunction)
        modifiers |= NSEventModifierFlagFunction;
    return modifiers;
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
    //--------------------
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    if(KSEQ("A"))
        return kVK_ANSI_A;
    if(KSEQ("S"))
        return kVK_ANSI_S;
    if(KSEQ("D"))
        return kVK_ANSI_D;
    return -1;
}

-(NSArray<NSString *> *)VirtualKeyStringFromCode:(NSInteger)keyCode
{
    return nil;
}

-(CGEventFlags)eventFlagsWithModifiers:(KeyboardModifiers)modifiers
{
    CGEventFlags flags = 0;
//    kCGEventFlagMaskAlphaShift =          NX_ALPHASHIFTMASK,
    if(modifiers & KeyboardModifiersCapsLock)
        flags |= kCGEventFlagMaskAlphaShift;
    if(modifiers & KeyboardModifiersCommand)
        flags |= kCGEventFlagMaskCommand;
    if(modifiers & KeyboardModifiersOption)
        flags |= kCGEventFlagMaskAlternate;
    if(modifiers & KeyboardModifiersControl)
        flags |= kCGEventFlagMaskControl;
    if(modifiers & KeyboardModifiersHelp)
        flags |= kCGEventFlagMaskHelp;
    if(modifiers & KeyboardModifiersShift)
        flags |= kCGEventFlagMaskShift;
    if(modifiers & KeyboardModifiersNumericPad)
        flags |= kCGEventFlagMaskNumericPad;
    if(modifiers & KeyboardModifiersFunction)
        flags |= kCGEventFlagMaskSecondaryFn;
    
    return flags;
}

@end
