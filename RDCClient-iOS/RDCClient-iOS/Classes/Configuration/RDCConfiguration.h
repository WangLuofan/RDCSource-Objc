//
//  RDCConfiguration.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/15.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDCConfiguration : NSObject

@property(nonatomic, copy, class) NSString* serverAddr;
@property(nonatomic, assign, class) NSUInteger serverPort;

@end
