//
//  LWSMapVIewMultiplyDelegate.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 05.12.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LWSMapViewMultiplyDelegate : NSObject
@property (nonatomic,strong)MKMapView*map;
-(void)setMapViewDelegate:(id)arg;
-(void)removeMapViewDelegate:(id)arg;

@end
