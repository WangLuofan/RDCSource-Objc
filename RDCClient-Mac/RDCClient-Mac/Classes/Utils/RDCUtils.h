//
//  RDCUtils.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface RDCUtils : NSObject

+(instancetype)sharedInstance;
-(NSString*)currentTimeStamp;
-(void)showAlertWithTitle:(NSString*)title message:(NSString*)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void(^)(NSModalResponse))completion;
-(void)beginSheetAlertForWindow:(NSWindow*)window title:(NSString*)title message:(NSString*)message style:(NSAlertStyle)style buttons:(NSArray<NSString*> *)buttons completion:(void(^)(NSModalResponse))completion;
-(void)beginTextInputSheetForWindow:(NSWindow*)window title:(NSString*)title message:(NSString*)message buttons:(NSArray<NSString*> *)buttons placeholders:(NSArray<NSString*> *)placeholders completion:(void(^)(NSModalResponse, NSArray<NSString*> *))completion;
-(NSString*)prettySystemVersionDescription;
-(NSString*)hostName;
-(void)removeWallpaper:(BOOL)bRemove;
-(NSString*)xResolution;
-(NSString*)yResolution;
-(NSData*)grabScreen;
-(NSData*)compressData:(NSData*)data;
-(NSData*)compressData:(const u_char*)data length:(NSInteger)length;
-(NSData*)uncompressData:(NSData*)data originLength:(NSInteger)oriLen;
-(KeyboardModifiers)modifiersFromNSEventModifierFlags:(NSEventModifierFlags)flags;
-(CGEventFlags)eventFlagsWithModifiers:(KeyboardModifiers)modifiers;
-(NSEventModifierFlags)modifiersFromKeyboardModifiers:(KeyboardModifiers)flags;
-(NSInteger)VirutalKeyCodeFromString:(NSString*)keyString;
-(NSArray<NSString*>*)VirtualKeyStringFromCode:(NSInteger)keyCode;

@end
