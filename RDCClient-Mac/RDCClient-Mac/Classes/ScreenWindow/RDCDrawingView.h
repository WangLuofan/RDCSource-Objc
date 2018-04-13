//
//  RDCDrawingView.h
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/27.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RDCDrawingView : NSView

@property(nonatomic, assign) CGSize resolution;
@property(nonatomic, assign) CGPoint mouseLocation;
@property(nonatomic, assign) NSData* imageData;

@end
