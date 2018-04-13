//
//  RDCServiceCommand.h
//  RDCServer
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#ifndef RDCServiceCommand_h
#define RDCServiceCommand_h

typedef NS_ENUM(NSUInteger, RDCServiceCommand)
{
    ServiceCommandUnknown = 'SCUK',
    ServiceCommandSYN = 'SCSN',                      //上线通知
    ServiceCommandACK = 'SCAK',                      //上线确认
    ServiceCommandConnectionQuery = 'SCCQ',          //连接查询
    ServiceCommandConnectionResponse = 'SCCR',       //连接请求
    ServiceCommandTokenNotFound = 'STNF',            //未注册的Token
    ServiceCommandConnectionDenied = 'SCCD',         //被控端拒绝连接
    ServiceCommandVerifyRequest = 'SCVR',            //被控端要求密码验证
    ServiceCommandVerifyComplete = 'SCVC',           //主控端验证通过
    ServiceCommandVerifyFailed = 'SCVF',             //主控端验证失败
    ServiceCommandConnectionReady = 'SCRY',          //被控端已准备好连接
    ServiceCommandResolutionRequest = 'RREQ',        //请求桌面分辨率
    ServiceCommandResolutionResponse = 'RRES',       //回应桌面分辨率
    ServiceCommandScreenFirstFrame = 'SFRM',         //主控端请求屏幕第一帧
    ServiceCommandScreenData = 'SCSD',               //被控端发送的屏幕数据
    ServiceCommandScreenDataNone = 'SCSN',           //无屏幕差异数据
    ServiceCommandKeyEvent = 'SKBE',                 //键盘事件
    ServiceCommandMouseLeftButtonDownEvent = 'MLBD',  //鼠标左键按下
    ServiceCommandMouseRightButtonDownEvent = 'MRBD', //鼠标右键按下
    ServiceCommandMouseDoubleClickEvent = 'MDCE',     //鼠标双击
    ServiceCommandMouseMoveEvent = 'SCME',           //鼠标移动
    ServiceCommandMouseWheelEvent = 'CMWE',          //鼠标滚轮
    ServiceCommandForceQuitEvent = 'CFQE',           //强制退出
    ServiceCommandScreenNextFrame = 'SNFR',          //主控端请求下一帧屏幕
    ServiceCommandConnectionCloseSYN = 'SCCS',       //主/被控端断开确认
    ServiceCommandConnectionCloseACK = 'SCCK',       //主/被控端断开回复
    ServiceCommandApplicationQuit = 'SCAQ',          //应用退出
};

typedef NS_ENUM(UInt8, KeyboardModifiers) {
    KeyboardModifiersCapsLock = 1 << 0,             //大小写锁定
    KeyboardModifiersShift = 1 << 1,                //Shift键
    KeyboardModifiersControl = 1 << 2,              //Ctrl键
    KeyboardModifiersOption = 1 << 3,               //Alt键
    KeyboardModifiersCommand = 1 << 4,              //Command键
    KeyboardModifiersNumericPad = 1 << 5,           //数字锁定键
    KeyboardModifiersHelp = 1 << 6,                 //帮助键
    KeyboardModifiersFunction = 1 << 7,             //Fn键
    KeyboardModifiersMask = 0x00,
};

typedef NS_ENUM(NSUInteger, MouseEventType) {
    MouseDownEventType = 1,
    MouseUpEventType,
    MouseMoveEventType,
};

#endif /* RDCServiceCommand_h */
