//
//  RDCScreenTopMenuView.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/20.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@class RDCScreenTopMenuView;
@protocol RDCScreenTopMenuViewDelegate <NSObject>

@optional
-(void)topMenuView:(RDCScreenTopMenuView*)topMenuView itemSelectedAtIndex:(NSInteger)index;

@end

@interface RDCScreenTopMenuView : UIView

@property(nonatomic, assign) id<RDCScreenTopMenuViewDelegate> delegate;

-(KeyboardModifiers)keyModifiers;
-(void)unSelect;

@end
