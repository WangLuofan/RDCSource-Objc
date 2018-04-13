//
//  RDCDrawingView.m
//  RDCClient-Mac
//
//  Created by 王落凡 on 2018/2/27.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCDrawingView.h"

@interface RDCDrawingView()

@end

@implementation RDCDrawingView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    return ;
}

-(void)setImageData:(NSData *)imageData {
    @autoreleasepool {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        CGContextRef bmpCtx = CGBitmapContextCreate((void*)imageData.bytes, _resolution.width, _resolution.height, 8, _resolution.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Little);
        CGImageRef theImage = CGBitmapContextCreateImage(bmpCtx);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(bmpCtx);
        
        PerformOnMainThread({
            self.layer.contents = (__bridge id _Nullable)(theImage);
            CGImageRelease(theImage);
        });
    }
    return ;
}

@end
