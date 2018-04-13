//
//  RDCScreenWindowController.h
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/27.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCWindowController.h"

@class RDCTcpSocket;
@interface RDCScreenWindowController : RDCWindowController

@property(nonatomic, strong) RDCTcpSocket* screenSocket;
@property(nonatomic, strong) RDCTcpSocket* commandSocket;

@end
