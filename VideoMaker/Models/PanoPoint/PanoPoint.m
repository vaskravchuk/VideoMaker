//
//  PanoPoint.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 30.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "PanoPoint.h"

@implementation PanoPoint
@synthesize heading,coordinates,elevation,imageFilePaths,panoID,pitch,tiltHeading,isHaveSavedDirection,savedHeading,savedTiltHeading,zoom;
- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
@end
