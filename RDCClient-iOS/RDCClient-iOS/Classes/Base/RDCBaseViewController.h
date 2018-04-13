//
//  RDCBaseViewController.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDCBaseViewController : UIViewController

-(void)showHUDOnlyText:(NSString*)text;
-(void)showHUDIndeterminateWithText:(NSString*)text;
-(void)showHUDIndeterminate;
-(void)hideHUD;
-(void)gotoBack;

@end
