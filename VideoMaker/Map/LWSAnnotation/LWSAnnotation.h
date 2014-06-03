//
//  LWSAnnotation.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 26.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface LWSAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) MKAnnotationView* annotationView;



@end
