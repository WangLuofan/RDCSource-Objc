//
//  RDCScreenTopMenuView.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/20.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCScreenTopMenuView.h"

@interface RDCScreenTopMenuView()

@property(nonatomic, weak) IBOutlet UIButton* closeButton;
@property(nonatomic, weak) IBOutlet UIButton* ctrlButton;
@property(nonatomic, weak) IBOutlet UIButton* altButton;
@property(nonatomic, weak) IBOutlet UIButton* cmdButton;
@property(nonatomic, weak) IBOutlet UIButton* escButton;
@property(nonatomic, weak) IBOutlet UIButton* moreButton;

@end

@implementation RDCScreenTopMenuView

-(IBAction)menuItemSelected:(UIButton*)sender {
    if([sender isEqual:_closeButton]
       || [sender isEqual:_moreButton] || [sender isEqual:_escButton])
    {
        if([self.delegate respondsToSelector:
            @selector(topMenuView:itemSelectedAtIndex:)])
        {
            [self.delegate topMenuView:self itemSelectedAtIndex:sender.tag];
        }
    }else {
        sender.selected = !sender.isSelected;
    }
    return ;
}

-(KeyboardModifiers)keyModifiers {
    KeyboardModifiers flags = KeyboardModifiersMask;
    
    if(_ctrlButton.isSelected == YES)
        flags |= KeyboardModifiersControl;
    if(_altButton.isSelected == YES)
        flags |= KeyboardModifiersOption;
    if(_cmdButton.isSelected == YES)
        flags |= KeyboardModifiersCommand;
    
    return flags;
}

-(void)unSelect {
    _ctrlButton.selected = NO;
    _altButton.selected = NO;
    _cmdButton.selected = NO;
    
    return ;
}

@end
