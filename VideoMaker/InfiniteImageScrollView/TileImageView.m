//
//  TIleImageView.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 02.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "TileImageView.h"
#import "ImageCache.h"

@interface TileImageView () {
    NSArray* imagesArray;
}
@end
@implementation TileImageView

-(void)setImagesArr:(NSArray*)arr {
    if (arr) {
        if (imagesArray && imagesArray.count != arr.count) {
            for (UIView* view in self.subviews) {
                [view removeFromSuperview];
            }
        }
        imagesArray = [NSArray arrayWithArray:arr];
        if (self.subviews.count == 0) {
            double size = 292.57;
            double x = 0;
            double y = 0;
            for (NSArray* arrX in imagesArray) {
                y=0;
                for (id imY in arrX) {
                    CGRect rectForDraw = CGRectMake(x, y, size, size);
                    UIImageView* imageView = [[UIImageView alloc] initWithFrame:rectForDraw];
                    [imageView setContentScaleFactor:1];
                    imageView.layer.contentsScale = 1;
                    [self addSubview:imageView];
                    y+=size-0.3;
                }
                x+=size-0.3;
            }
        }
        [self newImages];
    }
}

-(void)updateImages {
    int i = 0;
    for (NSArray* arrX in imagesArray) {
        for (NSString* imY in arrX) {
            @autoreleasepool {
                UIImageView* imV = self.subviews[i];
                UIWindow* w = [UIApplication sharedApplication].windows[0];
                CGRect rectForDrawConv = [w convertRect:imV.frame fromView:self];
                if (CGRectIntersectsRect(w.bounds, rectForDrawConv)) {
                    if (!imV.image) {
                        imV.image = [[ImageCache instance] imageFromFile:imY];
                    }
                }
                else {
                    imV.image = nil;
                }
                ++i;
            }
        }
    }
}

-(void)newImages {
    int i = 0;
    for (NSArray* arrX in imagesArray) {
        for (NSString* imY in arrX) {
            @autoreleasepool {
                UIImageView* imV = self.subviews[i];
                UIWindow* w = [UIApplication sharedApplication].windows[0];
                CGRect rectForDrawConv = [w convertRect:imV.frame fromView:self];
                if (CGRectIntersectsRect(w.bounds, rectForDrawConv)) {
                    imV.image = [[ImageCache instance] imageFromFile:imY];
                }
                else {
                    imV.image = nil;
                }
                ++i;
            }
        }
    }
}

#pragma mark - initialization

-(void)fillView {
    [self setOpaque:YES];
    [self setClearsContextBeforeDrawing:NO];
}

-(id)init {
    if (self = [super init]) {
        [self fillView];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self fillView];
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self fillView];
    }
    return self;
}

@end
