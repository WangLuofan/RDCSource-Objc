//
//  RDCScreenMenuView.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/20.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCScreenMenuView.h"

@interface RDCScreenMenuView()

@property(nonatomic, strong) UIWindow* coverWindow;

@end

@implementation RDCScreenMenuView

-(void)awakeFromNib {
    [super awakeFromNib];
    return ;
}

-(void)showMenu {
    if(_coverWindow == nil) {
        _coverWindow = [[UIWindow alloc] initWithFrame:SCREEN_BOUNDS];
        _coverWindow.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        
        UIViewController* viewController = [[UIViewController alloc] init];
        _coverWindow.rootViewController = viewController;
    }
    [_coverWindow.rootViewController.view addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.and.bottom.mas_equalTo
            (_coverWindow.rootViewController.view);
        make.width.mas_equalTo(150.0f);
        make.height.mas_equalTo(50.0f);
    }];
    [_coverWindow layoutIfNeeded];
    [_coverWindow makeKeyAndVisible];

    return ;
}

-(IBAction)menuItemSelected:(UIButton*)sender {
    if([self.delegate respondsToSelector:
        @selector(menuView:itemSelectedAtIndex:)])
    {
        [self hideMenu];
        [self.delegate menuView:self itemSelectedAtIndex:sender.tag];
    }
    return ;
}

-(IBAction)hideMenu {
    [self removeFromSuperview];
    [_coverWindow resignKeyWindow];
    _coverWindow.hidden = YES;
    return ;
}

@end
