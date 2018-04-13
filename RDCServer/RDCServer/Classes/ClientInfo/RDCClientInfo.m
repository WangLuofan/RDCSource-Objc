//
//  RDCClientInfo.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCClientInfo.h"

@implementation RDCClientInfo

-(void)setClientStatus:(RDCClientStatus)clientStatus {
    _clientStatus = clientStatus;
    
    switch (_clientStatus) {
        case ClientStatusOnline:
            _clientStatusDescription = @"在线";
            break;
        case ClientStatusOffline:
            _clientStatusDescription = @"离线";
            break;
        default:
            break;
    }
    
    return ;
}

@end
