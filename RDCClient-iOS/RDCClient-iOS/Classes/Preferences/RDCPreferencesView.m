//
//  RDCPreferencesView.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCConfiguration.h"
#import "RDCPreferencesView.h"

@interface RDCPreferencesView()

@property(nonatomic, strong) UIWindow* coverWindow;
@property(nonatomic, weak) IBOutlet UITextField* serverAddrTextField;
@property(nonatomic, weak) IBOutlet UITextField* serverPortTextField;

@end

@implementation RDCPreferencesView

-(void)awakeFromNib {
    [super awakeFromNib];
    
    _serverAddrTextField.text = RDCConfiguration.serverAddr;
    _serverPortTextField.text = [NSString stringWithFormat:@"%lu", (unsigned long)RDCConfiguration.serverPort];
    
    [RDCNotificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [RDCNotificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    return ;
}

- (void)dealloc
{
    [RDCNotificationCenter removeObserver:self];
}

-(void)bgTapped {
    [_serverAddrTextField resignFirstResponder];
    [_serverPortTextField resignFirstResponder];
    
    return ;
}

-(void)show {
    if(_coverWindow == nil) {
        _coverWindow = [[UIWindow alloc] initWithFrame:SCREEN_BOUNDS];
        _coverWindow.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [_coverWindow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgTapped)]];
    }
    
    self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.bounds.size.height);
    [_coverWindow addSubview:self];
    [_coverWindow makeKeyAndVisible];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.frame = CGRectMake(0, SCREEN_HEIGHT - self.bounds.size.height, SCREEN_WIDTH, self.bounds.size.height);
    }];
    return ;
}

-(IBAction)saveConfiguration:(id)sender {
    [self endEditing:YES];
    
    RDCConfiguration.serverAddr = _serverAddrTextField.text;
    RDCConfiguration.serverPort = _serverPortTextField.text.integerValue;
    
    return [self hide];
}

-(IBAction)hide {
    [UIView animateWithDuration:0.5f animations:^{
        self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, self.bounds.size.height);
    } completion:^(BOOL finished) {
        if(finished) {
            [_coverWindow resignKeyWindow];
            _coverWindow.hidden = YES;
            
            [self removeFromSuperview];
        }
    }];
    return ;
}

-(void)keyboardWillShow:(NSNotification*)notification {
    NSTimeInterval animTime = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if(self.frame.origin.y + self.frame.size.height > keyboardFrame.origin.y)
    {
        [UIView animateWithDuration:animTime animations:^{
            self.frame = CGRectMake(0, keyboardFrame.origin.y - self.bounds.size.height, SCREEN_WIDTH, self.bounds.size.height);
        }];
    }
    
    return ;
}

-(void)keyboardWillHide:(NSNotification*)notification {
    NSTimeInterval animTime = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animTime animations:^{
        self.frame = CGRectMake(0, SCREEN_HEIGHT - self.bounds.size.height, SCREEN_WIDTH, self.bounds.size.height);
    }];
    return ;
}

@end
