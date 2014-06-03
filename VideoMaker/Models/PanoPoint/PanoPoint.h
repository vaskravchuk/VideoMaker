//
//  PanoPoint.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 30.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface PanoPoint : NSObject
@property (nonatomic,strong)NSArray* imageFilePaths;
@property (nonatomic,strong)NSString* panoID;
@property (nonatomic,assign)CLLocationCoordinate2D coordinates;
@property (nonatomic,assign)double elevation;
@property (nonatomic,assign)double pitch;
@property (nonatomic,assign)double heading;
@property (nonatomic,assign)double zoom;
@property (nonatomic,assign)double tiltHeading;
@property (nonatomic,assign)BOOL isHaveSavedDirection;
@property (nonatomic,assign)double savedHeading;
@property (nonatomic,assign)double savedTiltHeading;

@end
