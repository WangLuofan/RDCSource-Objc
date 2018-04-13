//
//  RDCMultilineButton.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/20.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCMultilineButton.h"

@implementation RDCMultilineButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.titleLabel.numberOfLines = 0;
    }
    return self;
}

-(void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if(selected) {
        self.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.8f];
    }else {
        self.backgroundColor = nil;
    }
    
    return ;
}

@end
