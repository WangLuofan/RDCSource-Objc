//
//  RDCDrawingView.m
//  RDCClient-iOS
//
//  Created by 王落凡 on 2018/3/16.
//  Copyright © 2018年 王落凡. All rights reserved.
//

#import "RDCDrawingView.h"

@interface RDCDrawingView()

@property(nonatomic, strong) UIImageView* cursorImageView;

@end

@implementation RDCDrawingView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _cursorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _cursorImageView.contentMode = UIViewContentModeScaleAspectFit;
        _cursorImageView.image = [UIImage imageNamed:@"cursor_arrow"];
        [self addSubview:_cursorImageView];
    }
    return self;
}

-(void)setImageData:(NSData *)imageData {
    @autoreleasepool {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        CGContextRef bmpCtx = CGBitmapContextCreate((void*)imageData.bytes, _resolution.width, _resolution.height, 8, _resolution.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Little);
        CGImageRef theImage = CGBitmapContextCreateImage(bmpCtx);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(bmpCtx);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.layer.contents = (__bridge id _Nullable)(theImage);
            CGImageRelease(theImage);
        });
    }
    return ;
}

-(void)setMouseLocation:(CGPoint)mouseLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cursorImageView.frame = CGRectMake(mouseLocation.x, mouseLocation.y, self.cursorImageView.bounds.size.width, self.cursorImageView.bounds.size.height);
    });
    return ;
}
@end
