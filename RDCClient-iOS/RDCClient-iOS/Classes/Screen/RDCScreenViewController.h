//
//  RDCScreenViewController.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/16.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCBaseViewController.h"

@class RDCTcpSocket;
@interface RDCScreenViewController : RDCBaseViewController

-(void)performConnectionCloseAction:(BOOL)bPassive;

@property(nonatomic, strong) RDCTcpSocket* screenSocket;
@property(nonatomic, strong) RDCTcpSocket* commandSocket;

@end
