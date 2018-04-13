//
//  RDCScreenCustomKeyboard.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/21.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCCustomKeyboardItem.h"
#import "RDCScreenCustomKeyboard.h"

#define kKeyboardItemWidth 50
#define kKeyboardItemHeight 30
#define kKeyboardItemGapSize 2
#define kKeyboardItemCountPerCol 3
#define kKeyboardItemCountPerRow 13

@interface RDCScreenCustomKeyboard()

@property(nonatomic, strong) UIView* keyboardInnerView;

@end

@implementation RDCScreenCustomKeyboard

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bounces = NO;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        
        _keyboardInnerView = [[UIView alloc] init];
        _keyboardInnerView.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:_keyboardInnerView];
        
        [self initCustomKeyboard];
        self.contentSize = CGSizeMake(kKeyboardItemWidth * kKeyboardItemCountPerRow + (kKeyboardItemCountPerRow + 1) * kKeyboardItemGapSize, 0);
    }
    return self;
}

-(void)layoutSubviews {
    _keyboardInnerView.frame = CGRectMake(0, 0, kKeyboardItemWidth * kKeyboardItemCountPerRow + (kKeyboardItemCountPerRow + 1) * kKeyboardItemGapSize, kKeyboardItemCountPerCol * kKeyboardItemHeight + (kKeyboardItemCountPerCol + 1) * kKeyboardItemGapSize);
    return [super layoutSubviews];
}

-(void)initCustomKeyboard {
    NSArray* keyTitles_Row1 = @[@"F1", @"F2", @"F3", @"F4", @"F5", @"F6", @"", @"Insert", @"Home", @"PgUp", @"", @"", @""];
    NSArray* keyTitles_Row2 = @[@"F7", @"F8", @"F9", @"F10", @"F11", @"F12", @"", @"Del", @"End", @"PgDn", @"", @"Up", @""];
    NSArray* keyTitles_Row3 = @[@"Esc", @"Tab", @"", @"Print", @"Scroll", @"Pause", @"", @"", @"", @"", @"Left", @"Down", @"Right"];
    NSArray* keyTitles = @[keyTitles_Row1, keyTitles_Row2, keyTitles_Row3];
    
    for(int i = 0; i != keyTitles.count; ++i) {
        NSArray* titlesArr = [keyTitles objectAtIndex:i];
        for(int j = 0; j != titlesArr.count; ++j) {
            NSString* title = [titlesArr objectAtIndex:j];
            
            if(title.length > 0) {
                RDCCustomKeyboardItem* item = [RDCCustomKeyboardItem newInstance];
                [item setTitle:title forState:UIControlStateNormal];
                [item addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [_keyboardInnerView addSubview:item];
                item.frame = CGRectMake(j * kKeyboardItemWidth + (j + 1) * kKeyboardItemGapSize, i * kKeyboardItemHeight + (i + 1) * kKeyboardItemGapSize, kKeyboardItemWidth, kKeyboardItemHeight);
            }
        }
    }
    return ;
}

-(void)buttonPressed:(UIButton*)sender {
    if(self.itemPressed != nil)
        self.itemPressed([sender titleForState:UIControlStateNormal]);
    return ;
}

-(BOOL)isVisiable {
    return _visiable;
}

@end
