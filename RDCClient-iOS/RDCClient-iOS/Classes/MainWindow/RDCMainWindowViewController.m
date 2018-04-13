//
//  RDCMainWindowViewController.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCUtils.h"
#import "RDCMessage.h"
#import "RDCTcpSocket.h"
#import "RDCPreferencesView.h"
#import "RDCConfiguration.h"
#import "RDCScreenViewController.h"
#import "RDCMainWindowViewController.h"

@interface RDCMainWindowViewController () <RDCTcpSocketDelegate>

@property(nonatomic, strong) RDCTcpSocket* commandSocket;
@property(nonatomic, strong) RDCTcpSocket* screenSocket;
@property(nonatomic, strong) RDCTcpSocket* clientSocket;

@property(nonatomic, strong) NSThread* msgRecvThread;

@property(nonatomic, strong) RDCScreenViewController* screenViewController;
@property(nonatomic, strong) RDCPreferencesView* prefView;

@property(nonatomic, weak) IBOutlet UITextField* tokenTextField;

@property(nonatomic, copy) NSString* serverIPAddress;
@property(nonatomic, assign) UInt16 serverPort;

@end

@implementation RDCMainWindowViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"远程控制客户端";
    
    [RDCNotificationCenter addObserver:self selector:@selector(screenConnClosed:) name:RDCConnectionClosedNotification object:nil];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgTapped:)]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"icon_nav_setting"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(gotoPreferences)];
    
    [self showHUDIndeterminateWithText:@"正在连接远程服务器"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startConnection];
    });
    return ;
}

-(void)bgTapped:(UIGestureRecognizer*)recognizer {
    [self.view endEditing:YES];
    return ;
}

//断开连接，发送通知
-(void)screenConnClosed:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showHUDOnlyText:@"远程连接已关闭"];
    });
    
    _screenSocket = nil;
    _commandSocket = nil;
    
    RDCMessage* msg = nil;
    if(notification.object == nil) {
        msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionCloseACK];
    }else {
        msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionCloseSYN];
    }
    [_clientSocket sendMessage:msg];
    return ;
}

-(void)startConnection {
    if(_clientSocket == nil) {
        _clientSocket = [[RDCTcpSocket alloc] initSocketCreate];
        _clientSocket.delegate = self;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [_clientSocket connectToHost:RDCConfiguration.serverAddr Port:RDCConfiguration.serverPort];
    });
    
    return ;
}

-(IBAction)doConnection:(id)sender {
    [self.view endEditing:YES];
    
    if(_tokenTextField.text.length == 0) {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:@"Token不能为空，请检查后输入" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }
    
    RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandConnectionQuery];
    [msg appendChar:_tokenTextField.text.length];
    [msg appendString:_tokenTextField.text];
    [_clientSocket sendMessage:msg];
    return ;
}

-(void)gotoPreferences {
//    _screenViewController = [[RDCScreenViewController alloc] init];
//    [self.navigationController pushViewController:_screenViewController animated:YES];
//    return ;

    if(_prefView == nil)
        _prefView = (RDCPreferencesView*)[[[NSBundle mainBundle] loadNibNamed:@"RDCPreferencesView" owner:nil options:nil] objectAtIndex:0];
    [_prefView show];
    return ;
}

-(void)verifyThePasswordRecursive:(NSString*)password bFirst:(BOOL)bFirst onSocket:(RDCTcpSocket*)socket {
    
    static int count = 0;
    
    WeakObject(self);
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:(bFirst ? @"请输入对方的密码进行验证" : @"密码错误, 请重新验证") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"验证" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //验证按钮
        if([password isEqualToString:alertController.textFields.firstObject.text]) {
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
        return ;
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        RDCMessage* rmsg = [RDCMessage messageWithServiceCommand:ServiceCommandVerifyFailed];
        [socket sendMessage:rmsg];
        return ;
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入密码";
    }];
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
    return ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)startReceiveMessage {
    while(_msgRecvThread.isCancelled == NO) {
        [_clientSocket receiveMessage];
        [NSThread sleepForTimeInterval:0.01f];
    }
    return ;
}

#pragma mark - RDCTcpSocketDelegate
-(void)connectedToServerOnSocket:(RDCTcpSocket *)socket {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideHUD];
    });
    
    if([socket isEqual:_clientSocket]) {
        //启动数据接收线程
        _msgRecvThread = [[NSThread alloc] initWithTarget:self selector:@selector(startReceiveMessage) object:nil];
        [_msgRecvThread start];
        
        //发送SYN上线信息
        RDCMessage* msg = [RDCMessage messageWithServiceCommand:ServiceCommandSYN];
        NSString* hostName = [[RDCUtils sharedInstance] hostName];
        NSString* sysVersion = [[RDCUtils sharedInstance] prettySystemVersionDescription];
        
        [msg appendChar:hostName.length];
        [msg appendString:hostName];
        [msg appendChar:sysVersion.length];
        [msg appendString:sysVersion];
        
        [_clientSocket sendMessage:msg];
    }else if([socket isEqual:_screenSocket]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _screenViewController = [[RDCScreenViewController alloc] init];
            _screenViewController.screenSocket = socket;
            _screenViewController.title = [NSString stringWithFormat:@"%@[已连接]", _serverIPAddress];
            
            if(_commandSocket == nil) {
                _commandSocket = [[RDCTcpSocket alloc] initSocketCreate];
                _commandSocket.delegate = self;
            }
            [_commandSocket connectToHost:_serverIPAddress Port:_serverPort];
        });
        
    }else if([socket isEqual:_commandSocket]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _screenViewController.commandSocket = socket;
            [self.navigationController pushViewController:_screenViewController animated:YES];
        });
    }
    return ;
}

-(void)messageReceivedOnSocket:(RDCTcpSocket *)socket message:(RDCMessage *)message
{
    switch (message.serviceCommand) {
        case ServiceCommandConnectionDenied:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showHUDOnlyText:@"对方拒绝和您建立连接"];
            });
        }
            break;
        case ServiceCommandVerifyRequest:
        {
            int passLen = message.nextChar;
            NSString* password = [message nextString:passLen];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self verifyThePasswordRecursive:password bFirst:YES onSocket:socket];
            });
        }
            break;
        case ServiceCommandTokenNotFound:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showHUDOnlyText:@"未注册的Token, 请检查后输入"];
            });
        }
            break;
        case ServiceCommandConnectionCloseSYN:
        {
            //被控端要求关闭连接
            dispatch_async(dispatch_get_main_queue(), ^{
                if(_screenViewController != nil)
                    [_screenViewController performConnectionCloseAction:YES];
            });
        }
            break;
        case ServiceCommandConnectionReady:
        {
            //被控端连接已建立
            _serverPort = message.nextShort;
            
            int ipLen = message.nextChar;
            _serverIPAddress = [message nextString:ipLen];
            
            if(_screenSocket == nil) {
                _screenSocket = [[RDCTcpSocket alloc] initSocketCreate];
                _screenSocket.delegate = self;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showHUDIndeterminateWithText:@"正在连接被控端"];
            });
            [_screenSocket connectToHost:_serverIPAddress Port:_serverPort];
        }
            break;
        default:
            break;
    }
    return ;
}

-(void)errorOccuredOnSocket:(RDCTcpSocket *)socket desc:(NSString *)desc {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideHUD];
        [self showHUDOnlyText:desc];
    });
    [socket shutdown];
    return ;
}

@end
