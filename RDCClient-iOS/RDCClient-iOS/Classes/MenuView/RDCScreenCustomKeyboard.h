//
//  RDCScreenCustomKeyboard.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/21.
//  Copyright © 2018年 王落凡. All rights reserved.
//
@interface RDCScreenCustomKeyboard : UIScrollView

@property(nonatomic, assign, getter=isVisiable) BOOL visiable;
@property(nonatomic, copy) void(^itemPressed)(NSString*);

@end
