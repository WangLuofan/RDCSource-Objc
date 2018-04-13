//
//  RDCScreenMenuView.h
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/20.
//  Copyright © 2018年 王落凡. All rights reserved.
//

@class RDCScreenMenuView;
@protocol RDCScreenMenuViewDelegate <NSObject>

@optional
-(void)menuView:(RDCScreenMenuView*)menuView itemSelectedAtIndex:(NSInteger)index;

@end

@interface RDCScreenMenuView : UIView

@property(nonatomic, assign) id<RDCScreenMenuViewDelegate> delegate;

-(void)showMenu;

@end
