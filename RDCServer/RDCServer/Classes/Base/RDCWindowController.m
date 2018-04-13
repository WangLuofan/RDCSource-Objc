//
//  RDCWindowController.m
//  RDCServer
//
//  Created by 王落凡 on 2018/2/23.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCWindowController.h"

@interface RDCWindowController ()

@end

@implementation RDCWindowController

- (instancetype)init
{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    
    if(filePath == nil)
        self = [super init];
    else
        self = [super initWithWindowNibName:NSStringFromClass([self class])];
    
    if (self) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)dealloc {
    [RDCNotificationCenter removeObserver:self];
}

@end
