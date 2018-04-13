//
//  RDCCustomKeyboardItem.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/21.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCCustomKeyboardItem.h"

@implementation RDCCustomKeyboardItem

+(instancetype)newInstance {
    RDCCustomKeyboardItem* item = [super buttonWithType:UIButtonTypeCustom];
    [item initAppearence];
    
    return item;
}

-(void)initAppearence {
    self.layer.cornerRadius = 3.0f;
    self.layer.masksToBounds = YES;
    
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self setBackgroundImage:[self createImageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
    [self setBackgroundImage:[self createImageWithColor:[[UIColor blueColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    return ;
}

- (UIImage*) createImageWithColor: (UIColor*) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@end
