//
//  RouteManager.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 05.12.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "LWSMapViewMultiplyDelegate.h"


@protocol RouteManagerDelegate <NSObject>
@optional
-(void)routeLoaded;
-(void)routeLoadedError;

-(void)routeCreated;
-(void)routeDestroyed;

-(void)annotationIsSeleceted:(id)ann;
-(void)annotationIsDeseleceted:(id)ann;

@end

@interface RouteManager : NSObject

@property (nonatomic, strong)LWSMapViewMultiplyDelegate* mapMultiplyDelegate;
@property (nonatomic, strong)NSMutableArray *routePoints;
@property (nonatomic, strong)NSMutableArray *anotations;
@property (nonatomic, strong)NSMutableDictionary *routePolylines;
@property (nonatomic, assign)BOOL isCanEditRouteEnable;
@property (nonatomic, assign)BOOL isLoadingRoute;
@property (nonatomic, weak)id<RouteManagerDelegate> delegate;

-(void)addRoutePointToLocation:(CLLocationCoordinate2D)newLocation;
-(void)removeCurrentVideoPlace;
-(void)setCurrentVideoPlaceLocation:(CLLocationCoordinate2D)newLocation;
-(void)removeAllRouteObjects;
-(void)deleteRouteAnnotations:(id<MKAnnotation>)annArg NeedUpdate:(BOOL)needUpdateArg;
-(id)selectedAnotation;
-(void)addRoutePointsWithsSegment:(NSArray*)routesArg;

-(MKMapRect)boundingMapPolilynesRect;
@end
