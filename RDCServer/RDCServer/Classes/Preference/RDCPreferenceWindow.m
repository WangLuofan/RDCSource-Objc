//
//  RDCPreferenceWindow.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCConfiguration.h"
#import "RDCPreferenceWindow.h"

@interface RDCPreferenceWindow()

@property(nonatomic, weak) IBOutlet NSTextField* portTextField;

@end

@implementation RDCPreferenceWindow

-(void)awakeFromNib {
    [super awakeFromNib];
    
    _portTextField.objectValue = RDCConfiguration.standardConfiguration.serverPort;
    return ;
}

-(IBAction)save:(id)sender {
    RDCConfiguration.standardConfiguration.serverPort = _portTextField.objectValue;
    if(self.sheetParent != nil)
        [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
    return ;
}

-(IBAction)cancel:(id)sender {
    if(self.sheetParent != nil)
        [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
    return ;
}

@end
