//
//  RDCBaseViewController.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "MBProgressHUD.h"
#import "RDCBaseViewController.h"

@interface RDCBaseViewController ()

@end

@implementation RDCBaseViewController

- (instancetype)init
{
    NSString* nibFilePath = [[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if(nibFilePath == nil) {
        self = [super init];
    }else {
        self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]];
    }
    
    if (self) {
        
    }
    return self;
}

-(void)showHUDIndeterminate {
    return [self showHUDIndeterminateWithText:nil];
}

-(void)showHUDIndeterminateWithText:(NSString *)text {
    [self hideHUD];
    
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    hud.label.text = text;
    [self.view addSubview:hud];
    
    [hud showAnimated:YES];
    return ;
}

-(void)showHUDOnlyText:(NSString *)text {
    [self hideHUD];
    
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    hud.label.text = text;
    [self.view addSubview:hud];
    
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1.0f];
    return ;
}

-(void)hideHUD {
    MBProgressHUD* hud = [MBProgressHUD HUDForView:self.view];
    if(hud != nil)
        [hud hideAnimated:YES];
    return ;
}

-(void)gotoBack {
    if(self.navigationController != nil)
        [self.navigationController popViewControllerAnimated:YES];
    return ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden {
    return NO;
}

@end
