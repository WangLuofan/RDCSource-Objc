//
//  RDCPreferencesWindowController.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/26.
//  Copyright © 2018年 王落凡. All rights reserved.
//
#import "RDCConfiguration.h"
#import "RDCPreferencesWindowController.h"

@interface RDCPreferencesWindowController () <NSWindowDelegate>

@property(nonatomic, weak) IBOutlet NSTextField* serverAddrTextField;
@property(nonatomic, weak) IBOutlet NSTextField* serverPortTextField;
@property(nonatomic, weak) IBOutlet NSTextField* localPortTextField;
@property(nonatomic, weak) IBOutlet NSButton* autoAgreeBtn;
@property(nonatomic, weak) IBOutlet NSButton* deleteWallpaperBtn;
@property(nonatomic, weak) IBOutlet NSButton* captureMouseBtn;
@property(nonatomic, weak) IBOutlet NSButton* verifyPasswordBtn;

@end

@implementation RDCPreferencesWindowController

-(void)windowDidLoad {
    [super windowDidLoad];
    
    _serverAddrTextField.objectValue = RDCConfiguration.standardConfiguration.serverIPAddr;
    _serverPortTextField.objectValue = RDCConfiguration.standardConfiguration.serverPort;
    _localPortTextField.objectValue = RDCConfiguration.standardConfiguration.localPort;
    _autoAgreeBtn.state = (RDCConfiguration.standardConfiguration.shouldAutoAgree == YES ? NSControlStateValueOn : NSControlStateValueOff);
    _deleteWallpaperBtn.state = (RDCConfiguration.standardConfiguration.shouldDeleteWallpaper == YES ? NSControlStateValueOn : NSControlStateValueOff);
    _captureMouseBtn.state = (RDCConfiguration.standardConfiguration.shouldCaptureMouse == YES ? NSControlStateValueOn : NSControlStateValueOff);
    _verifyPasswordBtn.state = (RDCConfiguration.standardConfiguration.shouldVerifyPassword == YES ? NSControlStateValueOn : NSControlStateValueOff);
    
    return ;
}

-(void)windowWillClose:(NSNotification *)notification {
    return [NSApp stopModalWithCode:NSModalResponseCancel];
}

-(IBAction)save:(id)sender {
    RDCConfiguration.standardConfiguration.serverIPAddr = _serverAddrTextField.objectValue;
    RDCConfiguration.standardConfiguration.serverPort = _serverPortTextField.objectValue;
    RDCConfiguration.standardConfiguration.localPort = _localPortTextField.objectValue;
    RDCConfiguration.standardConfiguration.shouldAutoAgree = (_autoAgreeBtn.state == NSControlStateValueOn);
    RDCConfiguration.standardConfiguration.shouldCaptureMouse = (_captureMouseBtn.state == NSControlStateValueOn);
    RDCConfiguration.standardConfiguration.shouldDeleteWallpaper = (_deleteWallpaperBtn.state == NSControlStateValueOn);
    RDCConfiguration.standardConfiguration.shouldVerifyPassword = (_verifyPasswordBtn.state == NSControlStateValueOn);
    
    [RDCConfiguration.standardConfiguration saveConfiguration];
    
    [self close];
    return [NSApp stopModalWithCode:NSModalResponseOK];
}

-(IBAction)cancel:(id)sender {
    [self close];
    return [NSApp stopModalWithCode:NSModalResponseCancel];
}

@end
