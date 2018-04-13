//
//  RDCScreenViewController.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/16.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"
#import "RDCMessage.h"
#import "RDCTcpSocket.h"
#import "RDCDrawingView.h"
#import "RDCMessageQueue.h"
#import "RDCScreenMenuView.h"
#import "RDCScreenCustomKeyboard.h"
#import "RDCScreenTopMenuView.h"
#import "RDCTcpSocketInterface.h"
#import "RDCScreenViewController.h"

@interface RDCScreenViewController () <RDCTcpSocketDelegate, RDCScreenMenuViewDelegate, RDCScreenTopMenuViewDelegate, UIKeyInput> {
    unsigned char* oriBits;
    dispatch_semaphore_t _eventQueueSemaphore;
}

typedef NS_ENUM(NSUInteger, KeyboardState) {
    KeyboardStateNoneKeyboard,      //不显示键盘(关闭)
    KeyboardStateSystemKeyboard,    //显示系统键盘
    KeyboardStateCustomKeyboard,    //显示自定义的键盘
};

@property(nonatomic, strong) NSMutableData* comprData;  //压缩数据
@property(nonatomic, strong) NSMutableData* originData; //原数据

@property(nonatomic, assign) NSInteger comprSize;
@property(nonatomic, assign) NSInteger originSize;

@property(nonatomic, assign) CGPoint mouseLocation;
@property(nonatomic, strong) RDCDrawingView* drawingView;

@property(nonatomic, strong) NSThread* eventThread;
@property(nonatomic, strong) RDCMessageQueue* eventQueue;

@property(nonatomic, assign) NSInteger xResolution;
@property(nonatomic, assign) NSInteger yResolution;

@property(nonatomic, assign) KeyboardState keyboardState;
@property(nonatomic, strong) UIButton* menuButton;

@property(nonatomic, strong) NSThread* messageReceiveThread;

@property(nonatomic, strong) RDCScreenTopMenuView* screenTopMenuView;
@property(nonatomic, strong) RDCScreenMenuView* screenMenuView;
@property(nonatomic, strong) RDCScreenCustomKeyboard* externalKeyboard;

@end

@implementation RDCScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _eventQueueSemaphore = dispatch_semaphore_create(1);
    _comprData = [NSMutableData data];
    _originData = [NSMutableData data];
    
    [self addMonitorEventGestures];
    
    _drawingView = [[RDCDrawingView alloc] init];
    [self.view addSubview:_drawingView];
    [_drawingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
    _menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_menuButton setImage:[UIImage imageNamed:@"discovery_menu"] forState:UIControlStateNormal];
    [_menuButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_menuButton];
    [_menuButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view);
        make.trailing.mas_equalTo(self.view).mas_offset(-5.0f);
    }];
    
    _eventQueue = [[RDCMessageQueue alloc] init];
    
    _eventThread = [[NSThread alloc] initWithTarget:self selector:@selector(eventHandler) object:nil];
    [_eventThread start];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //先请求被控端屏幕分辨率
        RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandResolutionRequest];
        [_screenSocket sendMessage:msg];
    });
    return;
}

-(void)showMenu {
    if(_screenMenuView == nil) {
        _screenMenuView = (RDCScreenMenuView*)[[[NSBundle mainBundle] loadNibNamed:@"RDCScreenMenuView" owner:nil options:nil] objectAtIndex:0];
        _screenMenuView.delegate = self;
    }
    [_screenMenuView showMenu];
    return ;
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _drawingView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    return ;
}

-(void)eventHandler {
    while(_eventThread.isCancelled == NO)
    {
        dispatch_semaphore_wait(_eventQueueSemaphore, DISPATCH_TIME_FOREVER);
        
        while(_eventQueue.empty == NO) {
            RDCMessage* eventMsg = _eventQueue.pop_front;
            [_commandSocket sendMessage:eventMsg];
            
            [NSThread sleepForTimeInterval:0.01f];
        }
    }
    return;
}

-(CGPoint)remoteToScreen:(CGPoint)remote {
    __block CGPoint location = CGPointZero;
    location = CGPointMake(remote.x * SCREEN_WIDTH / _xResolution, (_yResolution - remote.y) * SCREEN_HEIGHT / _yResolution);
    return location;
}

-(CGPoint)screenToRemote:(CGPoint)screen {
    CGPoint location = CGPointZero;
    location = CGPointMake(screen.x * _xResolution / SCREEN_WIDTH, screen.y * _yResolution / SCREEN_HEIGHT);
    return location;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    return ;
}

-(void)performConnectionCloseAction:(BOOL)bPassive {
    [self showHUDIndeterminateWithText:@"正在关闭连接..."];
    {
        //关闭命令套接字及屏幕套接字
        [_commandSocket shutdown];
        [_screenSocket shutdown];
        
        //退出相关线程
        [_messageReceiveThread cancel];
        [_eventThread cancel];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
            
            if(bPassive == YES) {
                //被动关闭
                [RDCNotificationCenter postNotificationName:RDCConnectionClosedNotification object:nil];
            }else {
                [RDCNotificationCenter postNotificationName:RDCConnectionClosedNotification object:[NSObject new]];
            }
        });
    }
    return ;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    return ;
}

-(void)addMonitorEventGestures {
    UITapGestureRecognizer* leftTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mouseClickedEvent:)];
    leftTapGesture.numberOfTapsRequired = 1;
    leftTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:leftTapGesture];
    
    UITapGestureRecognizer* rightTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mouseClickedEvent:)];
    rightTapGesture.numberOfTapsRequired = 1;
    rightTapGesture.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:rightTapGesture];
    
    UITapGestureRecognizer* doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mouseClickedEvent:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:doubleTapGesture];
    
    UIPanGestureRecognizer* mouseMoveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mouseMovedEvent:)];
    mouseMoveGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:mouseMoveGesture];
    
    UIPanGestureRecognizer* mouseWheelGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mouseWheelEvent:)];
    mouseWheelGesture.maximumNumberOfTouches = 2;
    mouseWheelGesture.minimumNumberOfTouches = 2;
    [self.view addGestureRecognizer:mouseWheelGesture];
    
    return ;
}

-(void)mouseWheelEvent:(UIPanGestureRecognizer*)recognizer {
    CGPoint offset = [recognizer translationInView:self.view];
    
    if(offset.x > 10)
        offset.x = 10;
    if(offset.x < -10)
        offset.x = -10;
    if(offset.y > 10)
        offset.y = 10;
    if(offset.y < -10)
        offset.y = -10;
    
    unsigned int offset_x = (int)offset.x + 10;
    unsigned int offset_y = (int)offset.y + 10;
    
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandMouseWheelEvent];
    [msg appendInteger:offset_x];
    [msg appendInteger:offset_y];
    [_eventQueue push_back:msg];
    
    //唤醒线程，发送动作
    dispatch_semaphore_signal(_eventQueueSemaphore);
    return [recognizer setTranslation:CGPointZero inView:self.view];
}

-(void)mouseMovedEvent:(UIPanGestureRecognizer*)recognizer {
    CGPoint offset = [recognizer translationInView:self.view];
    
    _mouseLocation.x += offset.x;
    _mouseLocation.y -= offset.y;
    
    if(_mouseLocation.x < 0)
        _mouseLocation.x = 0;
    if(_mouseLocation.x > _xResolution)
        _mouseLocation.x = _xResolution;
    if(_mouseLocation.y < 0)
        _mouseLocation.y = 0;
    if(_mouseLocation.y > _yResolution)
        _mouseLocation.y = _yResolution;
    
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandMouseMoveEvent];
    [msg appendLongInteger:(unsigned long)(_mouseLocation.x * 100000)];
    [msg appendLongInteger:(unsigned long)((_yResolution - _mouseLocation.y) * 100000)];
    [_eventQueue push_back:msg];
    
    //唤醒线程，发送动作
    dispatch_semaphore_signal(_eventQueueSemaphore);
    return [recognizer setTranslation:CGPointZero inView:self.view];
}

-(void)mouseClickedEvent:(UITapGestureRecognizer*)recognizer {
    RDCServiceCommand serviceCommand = ServiceCommandUnknown;
    
    if(recognizer.numberOfTapsRequired == 1) {
        if(recognizer.numberOfTouchesRequired == 1)
            serviceCommand = ServiceCommandMouseLeftButtonDownEvent;
        else
            serviceCommand = ServiceCommandMouseRightButtonDownEvent;
    }else {
        serviceCommand = ServiceCommandMouseDoubleClickEvent;
    }
    
    RDCMessage* message = [RDCMessage messageWithServiceCommand:serviceCommand];
    [_eventQueue push_back:message];
    
    //唤醒线程，发送动作
    dispatch_semaphore_signal(_eventQueueSemaphore);
    return ;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setKeyboardState:(KeyboardState)keyboardState {
    _keyboardState = keyboardState;
    if(_keyboardState == KeyboardStateSystemKeyboard) {
        if(_screenTopMenuView == nil) {
            _screenTopMenuView = (RDCScreenTopMenuView*)[[[NSBundle mainBundle] loadNibNamed:@"RDCScreenTopMenuView" owner:nil options:nil] objectAtIndex:0];
            _screenTopMenuView.delegate = self;
            [self.view addSubview:_screenTopMenuView];
            [_screenTopMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.and.trailing.equalTo(self.view);
                make.bottom.mas_equalTo(self.view.mas_top);
                make.height.mas_equalTo(50.0f);
            }];
        }
        
        //如果自定义键盘显示，则隐藏自定义键盘
        if(_externalKeyboard != nil &&
           _externalKeyboard.visiable == YES)
        {
            _externalKeyboard.visiable = NO;
            [_externalKeyboard mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.and.trailing.mas_equalTo(self.view);
                make.top.mas_equalTo(self.view.mas_bottom);
                make.height.mas_equalTo(98.0f);
            }];
        }
        _screenTopMenuView.hidden = NO;
        [_screenTopMenuView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.and.trailing.equalTo(self.view);
            make.top.mas_equalTo(self.view.mas_top);
            make.height.mas_equalTo(50.0f);
        }];
        
        [self becomeFirstResponder];
    }else if(keyboardState == KeyboardStateNoneKeyboard) {
        [self resignFirstResponder];
        _screenTopMenuView.hidden = YES;
        [_screenTopMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.and.trailing.equalTo(self.view);
            make.bottom.mas_equalTo(self.view.mas_top);
            make.height.mas_equalTo(50.0f);
        }];
        
        //如果自定义键盘显示，则隐藏自定义键盘
        if(_externalKeyboard != nil &&
           _externalKeyboard.visiable == YES)
        {
            _externalKeyboard.visiable = NO;
            [_externalKeyboard mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.and.trailing.mas_equalTo(self.view);
                make.top.mas_equalTo(self.view.mas_bottom);
                make.height.mas_equalTo(98.0f);
            }];
        }
    }else {
        [self resignFirstResponder];
        if(_externalKeyboard == nil) {
            _externalKeyboard = [[RDCScreenCustomKeyboard alloc] init];
            
            WeakObject(self);
            _externalKeyboard.itemPressed = ^(NSString* keyName) {
                [weak_self pushKeyEventWithText:keyName hasText:nil];
            };
            
            [self.view addSubview:_externalKeyboard];
            [_externalKeyboard mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.and.trailing.mas_equalTo(self.view);
                make.top.mas_equalTo(self.view.mas_bottom);
                make.height.mas_equalTo(98.0f);
            }];
            
            [self.view layoutIfNeeded];
        }
        
        _externalKeyboard.visiable = YES;
        [_externalKeyboard mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.and.
                trailing.and.bottom.mas_equalTo(self.view);
            make.height.mas_equalTo(98.0f);
        }];
    }
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
    return ;
}

-(void)setScreenSocket:(RDCTcpSocket *)screenSocket {
    _screenSocket = screenSocket;
    _screenSocket.delegate = self;
    
    //启动数据接收线程
    _messageReceiveThread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveMessage) object:nil];
    [_messageReceiveThread start];
    return ;
}

-(void)receiveMessage {
    while(_messageReceiveThread.isCancelled == NO) {
        [_screenSocket receiveMessage];
        
        [NSThread sleepForTimeInterval:0.1f];
    }
    return ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if(_messageReceiveThread != nil)
        [_messageReceiveThread cancel];
    
    [RDCNotificationCenter removeObserver:self];
    
    free(oriBits);
    oriBits = NULL;
}

#pragma mark - RDCTcpSocketDelegate
-(void)messageReceivedOnSocket:(RDCTcpSocket *)socket message:(RDCMessage *)msg
{
    switch (msg.serviceCommand) {
        case ServiceCommandResolutionResponse:
        {
            //被控端回复分辨率
            NSString* resolution = [msg nextString:msg.size - msg.current];
            NSArray* comp = [resolution componentsSeparatedByString:@"x"];
            if(comp.count == 2) {
                _xResolution = [comp[0] integerValue];
                _yResolution = [comp[1] integerValue];
                
                _drawingView.resolution = CGSizeMake(_xResolution, _yResolution);
                _originSize = _xResolution * _yResolution * 4;
                
                //请求屏幕第一帧数据
                RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenFirstFrame];
                [_screenSocket sendMessage:rmsg];
            }
        }
            break;
        case ServiceCommandScreenData:
        {
            BOOL bHasMouseLocation = (BOOL)msg.nextChar;
            
            if(bHasMouseLocation == YES) {
                _mouseLocation.x = (CGFloat)msg.nextLongInteger / 100000;
                _mouseLocation.y = (CGFloat)msg.nextLongInteger / 100000;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _drawingView.mouseLocation = [self remoteToScreen:_mouseLocation];
            });
            
            _comprSize = msg.nextInteger;
            
            [_comprData appendData:[msg.data subdataWithRange:NSMakeRange(msg.current, msg.size - msg.current)]];
        }
            break;
        default:
            [_comprData appendData:msg.data];
            break;
    }
    
    if(_comprData.length == _comprSize && _comprData.length > 0 && _comprSize > 0)
    {
        NSData* uncomprData = [RDCUtils.sharedInstance uncompressData:_comprData originLength:_originSize];
        
        if(uncomprData != nil) {
            if(_originData.length == 0) {
                //填充alpha字节
                @autoreleasepool {
                    const UInt8* uncompr_ptr = (const UInt8*)uncomprData.bytes;
                    UInt8* data_ptr = (UInt8*)malloc(sizeof(UInt8) * _originSize);
                    memset(data_ptr, 0, sizeof(UInt8) * _originSize);
                    
                    int idx = 0;
                    for(int i = 0; i != _originSize; ++i) {
                        if((i + 1) % 4 != 0) {
                            *(data_ptr + i) = *(uncompr_ptr + idx);
                            ++idx;
                        }
                        else
                            *(data_ptr + i) = 0xFF;
                    }
                    
                    [_originData appendBytes:data_ptr length:_originSize];
                    free(data_ptr);
                }
            }else {
                @autoreleasepool {
                    if(oriBits == NULL) {
                        oriBits = (unsigned char*)malloc(sizeof(unsigned char) * _originSize);
                        memset(oriBits, 0xFF, sizeof(unsigned char) * _originSize);
                    }
                    
                    const unsigned char* cmp_ptr = uncomprData.bytes;
                    const unsigned char* ori_ptr = _originData.bytes;
                    
                    int idx = 0;
                    for(int i = 0; i != _originSize; ++i) {
                        if((i + 1) % 4 != 0) {
                            *(oriBits + i) = (*(ori_ptr + i)) ^ (*(cmp_ptr + idx));
                            ++idx;
                        }
                    }
                    [_originData replaceBytesInRange:NSMakeRange(0, _originSize) withBytes:oriBits];
                }
            }
            
            _drawingView.imageData = _originData;
            
            //删除原有压缩数据
            [_comprData resetBytesInRange:NSMakeRange(0, _comprData.length)];
            [_comprData setLength:0];
            
            //继续请求下一帧
            RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandScreenNextFrame];
            [_screenSocket sendMessage:rmsg];
        }
    }
    return ;
}

-(void)pushKeyEventWithText:(NSString*)text hasText:(BOOL)hasText
{
    NSInteger keycode = [RDCUtils.sharedInstance VirutalKeyCodeFromString:text];
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandKeyEvent];
    
    //platform type
    [msg appendString:PLATFORM_IOS];
    //virtual keycode
    [msg appendChar:(keycode == -1 ? 0xFF : (unsigned char)keycode)];
    //character
    if(hasText) {
        NSData* tmp = [text dataUsingEncoding:NSUTF8StringEncoding];
        [msg appendChar:tmp.length];
        [msg appendString:text];
    }else {
        [msg appendChar:0];
    }
    
    [msg appendChar:_screenTopMenuView.keyModifiers];
    
    [_eventQueue push_back:msg];
    dispatch_semaphore_signal(_eventQueueSemaphore);
    return ;
}

#pragma mark - UIKeyInput
-(BOOL)hasText {
    return YES;
}

-(BOOL)canBecomeFirstResponder {
    return _keyboardState == KeyboardStateSystemKeyboard;
}

//type: iOS, Mac, Lin, Win
-(void)insertText:(NSString *)text {
    [self pushKeyEventWithText:text hasText:YES];
    return ;
}

-(void)deleteBackward {
    [self pushKeyEventWithText:@"DEL" hasText:NO];
    return ;
}

-(UIKeyboardType)keyboardType {
    return UIKeyboardTypeAlphabet;
}

-(UITextAutocorrectionType)autocorrectionType {
    return UITextAutocorrectionTypeNo;
}

#pragma mark - RDCScreenMenuViewDelegate
-(void)menuView:(RDCScreenMenuView *)menuView itemSelectedAtIndex:(NSInteger)index
{
    if(index == 1) {
        //关闭当前连接
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:@"确定要关闭当前连接吗?" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performConnectionCloseAction:NO];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }else if(index == 2) {
        //弹出键盘
        self.keyboardState = KeyboardStateSystemKeyboard;
    }
    
    return ;
}



#pragma mark - RDCScreenTopMenuViewDelegate
-(void)topMenuView:(RDCScreenTopMenuView *)topMenuView itemSelectedAtIndex:(NSInteger)index
{
    if(index == 0) {
        //关闭键盘
        [topMenuView unSelect];
        self.keyboardState = KeyboardStateNoneKeyboard;
    }else if(index == 1) {
        //ESC按钮
        KeyboardModifiers modifiers = topMenuView.keyModifiers;
        if((modifiers & KeyboardModifiersCommand) != 0 && (modifiers & KeyboardModifiersOption) != 0)
        {
            RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandForceQuitEvent];
            [_eventQueue push_back:msg];
            dispatch_semaphore_signal(_eventQueueSemaphore);
        }
        else
            [self pushKeyEventWithText:@"Esc" hasText:NO];
    }else if(index == 2) {
        //更多按键
        if(self.keyboardState == KeyboardStateSystemKeyboard)
            self.keyboardState = KeyboardStateCustomKeyboard;
        else if(self.keyboardState == KeyboardStateCustomKeyboard)
            self.keyboardState = KeyboardStateSystemKeyboard;
    }
    return ;
}

@end
