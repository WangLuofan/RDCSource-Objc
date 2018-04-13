//
//  RDCMainWindowController.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"
#import "RDCTcpSocket.h"
#import "RDCMessage.h"
#import "RDCMessageQueue.h"
#import "RDCConfiguration.h"
#import "RDCMainWindowController.h"
#import "RDCScreenWindowController.h"
#import "RDCPreferencesWindowController.h"

#import <AppleScriptObjC/AppleScriptObjC.h>
#import <CoreGraphics/CoreGraphics.h>

@interface RDCMainWindowController () <RDCTcpSocketDelegate>

@property(nonatomic, strong) RDCScreenWindowController* screenWindowController;

@property(nonatomic, copy) NSData* previousImageData;

@property(nonatomic, weak) IBOutlet NSTextField* userTokenTextField;
@property(nonatomic, weak) IBOutlet NSTextField* userPassTextField;
@property(nonatomic, weak) IBOutlet NSTextField* otherTokenTextField;

//服务器通信线程
@property(nonatomic, strong) NSThread* clientThread;
//屏幕数据传输线程
@property(nonatomic, strong) NSThread* screenThread;
//用户指令传输线程
@property(nonatomic, strong) NSThread* commandThread;

@property(nonatomic, strong) NSLock* mousePositionLock;

//保存对端的地址信息
@property(nonatomic, copy) NSString* serverIPAddress;
@property(nonatomic, assign) UInt16 serverPort;

//服务器通信
@property(nonatomic, strong) RDCTcpSocket* clientSocket;
//用于客户端监听
@property(nonatomic, strong) RDCTcpSocket* serverSocket;
//用于屏幕数据传输的Socket
@property(nonatomic, strong) RDCTcpSocket* screenSocket;
//用于传输指令的Socket
@property(nonatomic, strong) RDCTcpSocket* commandSocket;
//强制退出脚本
@property(nonatomic, strong) NSAppleScript* forceQuitScript;
//指示当前客户端是主控端还是被控端
@property(nonatomic, assign) BOOL isMaster;

@end

@implementation RDCMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _mousePositionLock = [[NSLock alloc] init];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _clientThread = [[NSThread alloc] initWithTarget:self selector:@selector(startServerConnection) object:nil];
        [_clientThread start];
    });
    
    return ;
}

-(void)startServerConnection {
    if(_clientSocket == nil) {
        _clientSocket = [[RDCTcpSocket alloc] init];
        _clientSocket.delegate = self;
    }
    
    [_clientSocket
     connectToHost:RDCConfiguration.standardConfiguration.serverIPAddr Port:RDCConfiguration.standardConfiguration.serverPort.integerValue];
    return ;
}

-(IBAction)doConnection:(id)sender {
    _isMaster = YES;
    
    //连接
    if([_userTokenTextField.objectValue isEqualToString:[_otherTokenTextField.objectValue stringByReplacingOccurrencesOfString:@" " withString:@""]])
    {
        //不能与自己进行连接
        [RDCUtils.sharedInstance beginSheetAlertForWindow:self.window title:@"错误" message:@"无法与自己进行连接, 请检查Token" style:NSAlertStyleCritical buttons:@[@"取消"] completion:nil];
        return ;
    }
    
    //请求连接
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionQuery];
    
    NSString* token = _otherTokenTextField.objectValue;
    [msg appendChar:token.length];
    [msg appendString:token];
    
    [_clientSocket sendMessage:msg];
    return ;
}

-(IBAction)doDisconnection:(id)sender {
    [[RDCUtils sharedInstance] beginSheetAlertForWindow:self.window title:@"关闭" message:@"确定要断开当前连接吗?" style:NSAlertStyleInformational buttons:@[@"断开", @"取消"] completion:^(NSModalResponse result) {
        if(result == NSAlertFirstButtonReturn) {
            if(_isMaster == YES)
                [self performConnCloseAction];
            
            //断开连接请求
            RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionCloseSYN];
            [_clientSocket sendMessage:msg];
        }
    }];
    return ;
}

-(void)performConnCloseAction {
    if(_isMaster == NO) {
        //主控端已经断开连接
        if(_serverSocket != nil) {
            [_serverSocket close];
            _serverSocket = nil;
        }
        
        RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionCloseACK];
        [_clientSocket sendMessage:rmsg];
        
        PerformOnMainThread({
            //取消最小化状态
            if(self.window.isMiniaturized == YES)
                [self.window deminiaturize:nil];
            //如果删除了壁纸，断开连接后恢复壁纸
            if(RDCConfiguration.
               standardConfiguration.shouldDeleteWallpaper)
            {
                [[RDCUtils sharedInstance] removeWallpaper:NO];
            }
        });
    }else {
        [_commandSocket close];
        [_screenSocket close];
    }
    return ;
}

-(void)verifyThePasswordRecursive:(NSString*)password bFirst:(BOOL)bFirst onSocket:(RDCTcpSocket*)socket {
    
    static int count = 0;
    
    WeakObject(self);
    [RDCUtils.sharedInstance beginTextInputSheetForWindow:self.window title:(bFirst ? @"验证" : @"错误") message:(bFirst ? @"请输入对方的密码进行验证" : @"密码错误, 请重新验证") buttons:@[@"验证", @"放弃"] placeholders:@[@"请输入密码"] completion:^(NSModalResponse result, NSArray<NSString *> * text) {
        if(result == NSAlertFirstButtonReturn) {
            //验证按钮
            if([password isEqualToString:text.firstObject]) {
                //通过验证
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyComplete];
                [socket sendMessage:rmsg];
            }else {
                //反复验证
                ++count;
                
                if(count == 3) {
                    //最多验证三次
                    count = 0;
                    RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyFailed];
                    [socket sendMessage:rmsg];
                    return ;
                }
                
                [weak_self verifyThePasswordRecursive:password bFirst:NO onSocket:socket];
            }
        }else {
            RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyFailed];
            [socket sendMessage:rmsg];
            return ;
        }
    }];
    
    return ;
}

-(void)shouldAgreeConnection:(BOOL)bAgree onSocket:(RDCTcpSocket*)socket
{
    BOOL bShouldVerifyPass = RDCConfiguration.standardConfiguration.shouldVerifyPassword;
    
    RDCMessage* msg = nil;
    if(bAgree) {
        //同意连接, 如果需要验证密码，则发送密码验证请求
        msg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyRequest];
        [msg appendChar:(unsigned char)bShouldVerifyPass];
    }else {
        //拒绝连接，发送通知
        msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionDenied];
    }
    
    if(msg != nil)
        [socket sendMessage:msg];
    return ;
}

//启动监听
-(void)startScreenListen {
    _serverSocket = [[RDCTcpSocket alloc] init];
    _serverSocket.delegate = self;
    
    [_serverSocket listenAtPort:RDCConfiguration.
     standardConfiguration.localPort.integerValue];
    
    return ;
}

-(void)startScreenConnection {
    //连接到被控端
    _screenSocket = [[RDCTcpSocket alloc] init];
    _screenSocket.delegate = self;
    
    [_screenSocket connectToHost:_serverIPAddress Port:_serverPort];
    return ;
}

-(void)startCommandConnection {
    _commandSocket = [[RDCTcpSocket alloc] init];
    _commandSocket.delegate = self;
    
    [_commandSocket connectToHost:_serverIPAddress Port:_serverPort];
    return ;
}

-(void)gotoPreferences {
    RDCPreferencesWindowController* prefController = [[RDCPreferencesWindowController alloc] init];
    [NSApp runModalForWindow:prefController.window];
    
    return ;
}

-(CGPoint)getMouseLocation {
    CGEventRef event = CGEventCreate(NULL);
    CGPoint mouseLocation = CGEventGetLocation(event);
    CFRelease(event);
    
    return mouseLocation;
}

#pragma mark - RDCTcpSocketDelegate
-(void)connectedToServerOnSocket:(RDCTcpSocket *)socket {
    if([socket isEqual:_clientSocket]) {
        //成功连接到服务器，发送SYN给服务器
        RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandSYN];
        //获取主机名
        NSString* hostName = [RDCUtils.sharedInstance hostName];
        //系统版本信息
        NSString* systemVersion = [RDCUtils.sharedInstance prettySystemVersionDescription];
        
        [msg appendChar:hostName.length];
        [msg appendString:hostName];
        [msg appendChar:systemVersion.length];
        [msg appendString:systemVersion];
        
        //发送上线信息给服务器
        [socket sendMessage:msg];
    }else if([socket isEqual:_screenSocket]) {
        //屏幕socket已连接, 创建窗口, 准备接收图像
        if(_screenWindowController != nil) {
            PerformOnMainThread({
                [_screenWindowController close];
                _screenWindowController = nil;
            });
        }
        
        NSString* windowTitle = [NSString stringWithFormat:@"%@ [已连接]", _serverIPAddress];
        PerformOnMainThread({
            //最小化当前窗口
            [self.window miniaturize:nil];
            
            //创建并显示屏幕窗口
            _screenWindowController = [[RDCScreenWindowController alloc] init];
            _screenWindowController.window.title = windowTitle;
            _screenWindowController.screenSocket = _screenSocket;
        });
        
        //启动指令连接线程
        _commandThread = [[NSThread alloc] initWithTarget:self selector:@selector(startCommandConnection) object:nil];
        [_commandThread start];
    }else if([socket isEqual:_commandSocket]) {
        PerformOnMainThread({
            _screenWindowController.commandSocket = _commandSocket;
            [_screenWindowController showWindow:nil];
        });
    }
    return ;
}

-(void)clientConnectedWithOnNewSocket:(RDCTcpSocket *)newSocket addr:(RDCHostInfo *)addr
{
    if(self.window.isMiniaturized == NO) {
        PerformOnMainThread({
            //最小化当前窗口
            [self.window miniaturize:nil];
            //如果选择删除壁纸，连接建立之后，删除壁纸
            if(RDCConfiguration.
               standardConfiguration.shouldDeleteWallpaper)
            {
                [[RDCUtils sharedInstance] removeWallpaper:YES];
            }
        });
    }
    
    newSocket.delegate = self;
    if(_screenSocket == nil) {
        _screenSocket = newSocket;
    }else if(_commandSocket == nil) {
        _commandSocket = newSocket;
    }
    return ;
}

//连接已经断开，关闭服务器
-(void)clientDisconnectedOnSocket:(RDCTcpSocket *)socket {
    [socket close];
    
    if([socket isEqual:_screenSocket])
        _screenSocket = nil;
    if([socket isEqual:_commandSocket])
        _commandSocket = nil;
    
    return ;
}

-(void)messageReceivedOnSocket:(RDCTcpSocket *)socket message:(RDCMessage *)message
{
    @autoreleasepool {
        switch (message.serviceCommand) {
            case ServiceCommandACK:
            {
                //服务端回复ACK信息, 从中获取Token及Password
                int tokLen = message.nextChar;
                NSMutableString* token = [[message nextString:tokLen] mutableCopy];
                [token insertString:@"  " atIndex:2];
                
                int passLen = message.nextChar;
                NSMutableString* password = [[message nextString:passLen] mutableCopy];
                [password insertString:@"  " atIndex:4];
                
                //更新UI
                PerformOnMainThread({
                    _userTokenTextField.objectValue = token;
                    _userPassTextField.objectValue = password;
                });
            }
                break;
            case ServiceCommandConnectionQuery:
            {
                _isMaster = NO;
                
                //收到连接请求
                BOOL bShouldAutoAgree = RDCConfiguration.standardConfiguration.shouldAutoAgree;
                
                int hIfoLen = message.nextChar;
                NSString* hostInfo = [message nextString:hIfoLen];
                
                NSString* prompt = [NSString stringWithFormat:@"来自%@的请求，是否同意连接?", hostInfo];
                
                if(bShouldAutoAgree == YES) {
                    //如果允许自动同意
                    [self shouldAgreeConnection:YES onSocket:socket];
                }else {
                    //不允许自动同意，显示对话框给用户
                    NSArray* btns = @[@"同意", @"拒绝"];
                    PerformOnMainThread({
                        WeakObject(self);
                        [RDCUtils.sharedInstance beginSheetAlertForWindow:self.window title:@"请求" message:prompt style:NSAlertStyleInformational buttons:btns completion:^(NSModalResponse res) {
                            if(res == NSAlertFirstButtonReturn) {
                                //同意连接
                                [weak_self shouldAgreeConnection:YES onSocket:socket];
                            }else {
                                //拒绝连接
                                [weak_self shouldAgreeConnection:NO onSocket:socket];
                            }
                        }];
                    });
                }
            }
                break;
            case ServiceCommandTokenNotFound:
            {
                PerformOnMainThread({
                    //未注册的Token
                    [RDCUtils.sharedInstance beginSheetAlertForWindow:self.window title:@"错误" message:@"此Token尚未注册, 请检查或与对方联系" style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
                });
            }
                break;
            case ServiceCommandConnectionDenied:
            {
                //连接被拒绝
                PerformOnMainThread({
                    [RDCUtils.sharedInstance beginSheetAlertForWindow:self.window title:@"被拒绝" message:@"对方拒绝和您建立连接" style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
                });
            }
                break;
            case ServiceCommandVerifyFailed:
            {
                //验证未通过
                PerformOnMainThread({
                    [RDCUtils.sharedInstance beginSheetAlertForWindow:self.window title:@"失败" message:@"对方验证密码已失败" style:NSAlertStyleCritical buttons:@[@"确定"] completion:nil];
                });
            }
                break;
            case ServiceCommandVerifyRequest:
            {
                //收到密码验证请求
                int pasLen = message.nextChar;
                NSString* password = [message nextString:pasLen];
                
                PerformOnMainThread({
                    [self verifyThePasswordRecursive:password bFirst:YES onSocket:socket];
                });
            }
                break;
            case ServiceCommandVerifyComplete:
            {
                //对方验证密码通过，建立连接
                NSInteger port = RDCConfiguration.
                standardConfiguration.localPort.integerValue;
                
                //发送连接建立消息
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionReady];
                
                //添加数据端口/命令端口号
                [rmsg appendShort:port];
                [socket sendMessage:rmsg];
                
                //启动数据监听线程
                _screenThread = [[NSThread alloc] initWithTarget:self selector:@selector(startScreenListen) object:nil];
                [_screenThread start];
            }
                break;
            case ServiceCommandConnectionReady:
            {
                //被控端连接已建立
                _serverPort = message.nextShort;
                
                int ipLen = message.nextChar;
                _serverIPAddress = [message nextString:ipLen];
                
                //启动数据连接线程
                _screenThread = [[NSThread alloc] initWithTarget:self selector:@selector(startScreenConnection) object:nil];
                [_screenThread start];
            }
                break;
            case ServiceCommandResolutionRequest:
            {
                //主控端请求分辨率
                NSString* resolution = [NSString stringWithFormat:@"%@x%@", [RDCUtils.sharedInstance xResolution], [RDCUtils.sharedInstance yResolution]];
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandResolutionResponse];
                [rmsg appendString:resolution];
                [socket sendMessage:rmsg];
            }
                break;
            case ServiceCommandScreenFirstFrame:
            {
                [_mousePositionLock lock];
                NSPoint mouseLocation = NSEvent.mouseLocation;
                [_mousePositionLock unlock];
                
                //抓取屏幕
                _previousImageData = [RDCUtils.sharedInstance grabScreen];
                NSData* comprData = [RDCUtils.sharedInstance compressData:_previousImageData];
                
                if(comprData != nil) {
                    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenData];
                    [msg appendChar:1];
                    [msg appendLongInteger:(NSUInteger)(mouseLocation.x * 100000)];
                    [msg appendLongInteger:(NSUInteger)(mouseLocation.y * 100000)];
                    [msg appendInteger:(unsigned int)comprData.length];
                    [msg appendData:comprData];
                    [socket sendMessage:msg];
                }
            }
                break;
            case ServiceCommandScreenNextFrame:
            {
                //主控端请求屏幕下一帧数据
                NSData* screenImage = [RDCUtils.sharedInstance grabScreen];
                
                //差异数据
                u_char* diff = (u_char*)malloc(sizeof(u_char) * screenImage.length);
                memset(diff, 0, sizeof(u_char) * screenImage.length);
                
                //获取差异数据
                const u_char* pre_ptr = _previousImageData.bytes;
                const u_char* cur_ptr = screenImage.bytes;
                for(int i = 0; i != screenImage.length; ++i)
                    *(diff + i) = (*(pre_ptr + i)) ^ (*(cur_ptr + i));
                NSData* diffData = [NSData dataWithBytes:diff length:screenImage.length];
                free(diff);
                
                //替换原数据
                _previousImageData = screenImage;
                NSData* comprData = [RDCUtils.sharedInstance compressData:diffData];
                
                if(comprData != nil) {
                    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenData];
                    [msg appendChar:0];
                    [msg appendInteger:(unsigned int)comprData.length];
                    [msg appendData:comprData];
                    [socket sendMessage:msg];
                }
            }
                break;
            case ServiceCommandMouseLeftButtonDownEvent:
            {
                CGPoint mouseLocation = CGPointMake(NSEvent.mouseLocation.x, [NSScreen mainScreen].frame.size.height - NSEvent.mouseLocation.y);
                CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, mouseLocation, kCGMouseButtonLeft);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CGEventSetType(mouseEvent, kCGEventLeftMouseUp);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CFRelease(mouseEvent);
            }
                break;
            case ServiceCommandMouseRightButtonDownEvent:
            {
                CGPoint mouseLocation = CGPointMake(NSEvent.mouseLocation.x, [NSScreen mainScreen].frame.size.height - NSEvent.mouseLocation.y);
                CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, mouseLocation, kCGMouseButtonRight);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CGEventSetType(mouseEvent, kCGEventRightMouseUp);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CFRelease(mouseEvent);
            }
                break;
            case ServiceCommandMouseDoubleClickEvent:
            {
                CGPoint mouseLocation = CGPointMake(NSEvent.mouseLocation.x, [NSScreen mainScreen].frame.size.height - NSEvent.mouseLocation.y);
                CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, mouseLocation, kCGMouseButtonLeft);
                CGEventSetIntegerValueField(mouseEvent, kCGMouseEventClickState, 2);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CGEventSetType(mouseEvent, kCGEventLeftMouseUp);
                CGEventPost(kCGHIDEventTap, mouseEvent);
                
                CFRelease(mouseEvent);
            }
                break;
            case ServiceCommandMouseMoveEvent:
            {
                [_mousePositionLock lock];
                CGPoint mouseLocation = CGPointZero;
                mouseLocation.x = (CGFloat)message.nextLongInteger / 100000;
                mouseLocation.y = (CGFloat)message.nextLongInteger / 100000;
                
                CGDisplayMoveCursorToPoint(CGMainDisplayID(), mouseLocation);
                [_mousePositionLock unlock];
            }
                break;
            case ServiceCommandMouseWheelEvent:
            {
                int offset_x = 0, offset_y = 0;
                
                offset_x = message.nextInteger - 10;
                offset_y = message.nextInteger - 10;
                
                CGEventRef mouseWheel = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 2, offset_y, offset_x);
                CGEventPost(kCGHIDEventTap, mouseWheel);
                CFRelease(mouseWheel);
            }
                break;
            case ServiceCommandForceQuitEvent:
            {
                //强制退出，使用AppleScript
                if(_forceQuitScript == nil) {
                    NSString* script = @"tell application \"System Events\"\r key code 53 using {command down, option down}\r end tell";
                    _forceQuitScript = [[NSAppleScript alloc] initWithSource:script];
                }
                [_forceQuitScript executeAndReturnError:nil];
            }
                break;
            case ServiceCommandConnectionCloseACK:
            case ServiceCommandConnectionCloseSYN:
            {
                [self performConnCloseAction];
            }
                break;
            case ServiceCommandKeyEvent:
            {
                //iOS, Mac, Win, Lin
                NSString* type = [message nextString:3];
                
                //iOS平台
                if(IS_PLATFORM_IOS(type)) {
                    unsigned char keycode = message.nextChar;
                    unsigned char charLen = message.nextChar;
                    
                    CGEventRef keyEvent = CGEventCreateKeyboardEvent(NULL, (keycode == 0xFF ? 0x00 : keycode), YES);
                    if(charLen != 0) {
                        NSData* data = [message nextData:charLen];
                        NSString* character = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        const unsigned short* charPtr = (const unsigned short*)[character cStringUsingEncoding:NSUTF16StringEncoding];
                        CGEventKeyboardSetUnicodeString(keyEvent, sizeof(unichar), charPtr);
                    }
                    
                    KeyboardModifiers modifiers = (KeyboardModifiers) message.nextChar;
                    if(modifiers != KeyboardModifiersMask) {
                        CGEventFlags flags = [RDCUtils.sharedInstance eventFlagsWithModifiers:modifiers];
                        CGEventSetFlags(keyEvent, flags);
                    }
                    CGEventPost(kCGHIDEventTap, keyEvent);
                    
                    CGEventSetType(keyEvent, kCGEventKeyUp);
                    CGEventPost(kCGHIDEventTap, keyEvent);
                    CFRelease(keyEvent);
                }
                else if(IS_PLATFORM_MAC(type))
                {
                    //Mac平台
                }
            }
                break;
            default:
                break;
        }
    }
}

@end
