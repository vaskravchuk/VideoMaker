//
//  LWSAnnotationView.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 03.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface LWSAnnotationView : MKAnnotationView {
	@private
//	MKMapView *mapView_;

	BOOL isMoving_;
	CGPoint startLocation_;
	CGPoint originalCenter_;
	UIImageView *pinShadow_;
	NSTimer *pinTimer_;	
}

@property (nonatomic,strong)UIImage* pinImage;
@property (nonatomic,strong)UIImage* pinFloatingImage;
@property (nonatomic,strong)UIImage* pinDown1Image;
@property (nonatomic,strong)UIImage* pinDown2Image;
@property (nonatomic,strong)UIImage* pinDown3Image;
@property (nonatomic,assign)int state;//0 = start 1 = simple 2 = finished

// Please use this class method to create DDAnnotationView (on iOS 3) or built-in draggble MKPinAnnotationView (on iOS 4).
+ (id)annotationViewWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier mapView:(MKMapView *)mapView;

@end
