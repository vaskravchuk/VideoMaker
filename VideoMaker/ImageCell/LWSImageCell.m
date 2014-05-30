//
//  LWSImageCell.m
//  VideoMaker
//
//  Created by Василий Кравчук on 28.05.14.
//  Copyright (c) 2014 lifewaresolutions. All rights reserved.
//

#import "LWSImageCell.h"
@interface LWSImageCell () {
    UIImageView* imageView;
}

@end

@implementation LWSImageCell
@synthesize imageView;

-(void)fillViewAfterInit {
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self.contentView addSubview:imageView];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self fillViewAfterInit];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self fillViewAfterInit];
    }
    return self;
}
- (id)init
{
    self = [super init];
    if (self) {
        [self fillViewAfterInit];
    }
    return self;
}

@end
