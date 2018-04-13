//
//  RDCBaseNavigationController.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCBaseViewController.h"
#import "RDCBaseNavigationController.h"

@interface RDCBaseNavigationController ()

@end

@implementation RDCBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pushViewController:(RDCBaseViewController *)viewController animated:(BOOL)animated
{
    if(self.viewControllers.count > 0)
    {
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"BACK"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:viewController action:@selector(gotoBack)];
    }
    return [super pushViewController:viewController animated:animated];
}

-(BOOL)prefersStatusBarHidden {
    return [self.topViewController prefersStatusBarHidden];
}

@end
