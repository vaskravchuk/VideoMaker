//
//  RouteManager.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 05.12.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "RouteManager.h"
#import "LWSAnnotation.h"
#import "LWSAnnotationView.h"
#import "LWSDirectionService.h"
#import <CoreLocation/CoreLocation.h>

@interface RouteManager () <LWSDirectionServiceDelegate,MKMapViewDelegate> {
    NSMutableDictionary *routeForAnnotationPoints;
    
    
    LWSDirectionService* directionService;
    
    LWSAnnotation* currentVideoPlace;
    
    MKMapView* map;
}

@end
@implementation RouteManager

@synthesize mapMultiplyDelegate,routePoints,anotations,delegate,isCanEditRouteEnable,routePolylines;

-(id)init {
    if (self == [super init]) {
        if (!routePolylines) {
            routePolylines = [NSMutableDictionary dictionary];
        }
        if (!routePoints) {
            routePoints = [NSMutableArray array];
        }
        if (!routeForAnnotationPoints) {
            routeForAnnotationPoints = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

-(MKMapRect)boundingMapPolilynesRect {
    MKMapRect boundingMapRect;
    NSArray* routePolilynes = self.routePolylines.allValues;
    for (int i = 0; i < [routePolilynes count]; ++i) {
        MKPolyline* item = routePolilynes[i];
        if (i == 0) {
            boundingMapRect = [item boundingMapRect];
        }
        else {
            boundingMapRect = MKMapRectUnion(boundingMapRect, [item boundingMapRect]);
        }
    }
    return boundingMapRect;
}

#pragma mark - properties

-(void)setIsCanEditRouteEnable:(BOOL)isDraggingEnableArg {
    isCanEditRouteEnable = isDraggingEnableArg;
    if (isCanEditRouteEnable && currentVideoPlace) {
        [map removeAnnotation:currentVideoPlace];
        currentVideoPlace = nil;
    }
    for (id ann in anotations) {
        LWSAnnotationView* annView = (LWSAnnotationView*)[map viewForAnnotation:ann];
        
        [annView setDraggable:isCanEditRouteEnable];
    }
}
-(BOOL)isCanEditRouteEnable {
    return isCanEditRouteEnable;
}
-(void)setMapMultiplyDelegate:(LWSMapViewMultiplyDelegate *)mapMultiplyDelegateArg {
    mapMultiplyDelegate = mapMultiplyDelegateArg;
    map = mapMultiplyDelegate.map;
    [mapMultiplyDelegate setMapViewDelegate:self];
}
-(LWSMapViewMultiplyDelegate*)mapMultiplyDelegate {
    return mapMultiplyDelegate;
}

#pragma mark - points

-(void)updateAnnotations {
    for (int i = 0; i < [anotations count]; ++i) {
        LWSAnnotationView* annView = (LWSAnnotationView*)[map viewForAnnotation:anotations[i]];
        if (annView) {
            if (i == 0 && annView.state != 0) {
                annView.state = 0;
                [self setAnotationsViewAsStart:annView];
            }
            else if (i == [anotations count] - 1 && annView.state != 2) {
                annView.state = 2;
                [self setAnotationsViewAsFinished:annView];
            }
            else if (i > 0 && i < [anotations count] - 1 && annView.state != 1) {
                annView.state = 1;
                [self setAnotationsViewAsSimple:annView];
            }
        }
    }
}

-(void)setAnotationsViewAsStart:(LWSAnnotationView*)annView {
    ((LWSAnnotationView*)annView).pinImage = [UIImage imageNamed:@"flag_start.png"];
    ((LWSAnnotationView*)annView).pinFloatingImage = [UIImage imageNamed:@"flag_startFloating.png"];
    ((LWSAnnotationView*)annView).pinDown1Image = [UIImage imageNamed:@"flag_startDown1.png"];
    ((LWSAnnotationView*)annView).pinDown2Image = [UIImage imageNamed:@"flag_startDown2.png"];
    ((LWSAnnotationView*)annView).pinDown3Image = [UIImage imageNamed:@"flag_startDown3.png"];
}
-(void)setAnotationsViewAsFinished:(LWSAnnotationView*)annView {
    ((LWSAnnotationView*)annView).pinImage = [UIImage imageNamed:@"flag_finish.png"];
    ((LWSAnnotationView*)annView).pinFloatingImage = [UIImage imageNamed:@"flag_finishFloating.png"];
    ((LWSAnnotationView*)annView).pinDown1Image = [UIImage imageNamed:@"flag_finishDown1.png"];
    ((LWSAnnotationView*)annView).pinDown2Image = [UIImage imageNamed:@"flag_finishDown2.png"];
    ((LWSAnnotationView*)annView).pinDown3Image = [UIImage imageNamed:@"flag_finishDown3.png"];
}
-(void)setAnotationsViewAsSimple:(LWSAnnotationView*)annView {
    ((LWSAnnotationView*)annView).pinImage = [UIImage imageNamed:@"flag.png"];
    ((LWSAnnotationView*)annView).pinFloatingImage = [UIImage imageNamed:@"flagFloating.png"];
    ((LWSAnnotationView*)annView).pinDown1Image = [UIImage imageNamed:@"flagDown1.png"];
    ((LWSAnnotationView*)annView).pinDown2Image = [UIImage imageNamed:@"flagDown2.png"];
    ((LWSAnnotationView*)annView).pinDown3Image = [UIImage imageNamed:@"flagDown3.png"];
}

-(void)setCurrentVideoPlaceLocation:(CLLocationCoordinate2D)newLocation {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!currentVideoPlace) {
            currentVideoPlace = [[LWSAnnotation alloc] init];
            currentVideoPlace.coordinate = newLocation;
            currentVideoPlace.title = @"Scene position";
            
            [map addAnnotation:currentVideoPlace];
        }
        else {
            currentVideoPlace.coordinate = newLocation;
        }
    }];
}
-(void)removeAllRouteObjects {
    [routePoints removeAllObjects];
    [self removeCurrentVideoPlace];
    
    [map removeOverlays:[routePolylines allValues]];
    [map removeAnnotations:anotations];
    [anotations removeAllObjects];
    [routePolylines removeAllObjects];
    [routeForAnnotationPoints removeAllObjects];
    [directionService stopLoading];
}
-(void)removeCurrentVideoPlace {
    if (currentVideoPlace) {
        [map removeAnnotation:currentVideoPlace];
        currentVideoPlace = nil;
    }
}
-(void)addRoutePointsWithsSegment:(NSArray*)routesArg {
    if (!anotations) {
        anotations = [NSMutableArray array];
    }
    
    NSArray* prevSegment;
    for (NSArray* segmRoute in routesArg) {
        if (segmRoute.count > 0) {
            CLLocationCoordinate2D coordFS = [(NSValue*)segmRoute[0] MKCoordinateValue];
            [anotations addObject:[self annotationsForCoordinate:coordFS]];
            if (prevSegment) {
                [self directionReceived:nil Data:prevSegment userInfo:[anotations lastObject]];
            }
            prevSegment = segmRoute;
        }
    }
    
    if (anotations.count > 0) {
        [map addAnnotations:anotations];
        [self performSelector:@selector(selectAnnotation:) withObject:[anotations lastObject] afterDelay:0.4];
    }
}
-(void)addRoutePointToLocation:(CLLocationCoordinate2D)newLocation {
    if (!anotations) {
        anotations = [NSMutableArray array];
    }
    
    id ann = [self addNewAnnotationForCoordinate:newLocation];
    
    if ([anotations count] > 1) {
        [self updateRouteForPoints:[NSArray arrayWithObjects:anotations[[anotations count] - 2],anotations[[anotations count] - 1], nil] UserInfo:ann];
    }
    
    [self performSelector:@selector(selectAnnotation:) withObject:ann afterDelay:0.4];
}
-(void)selectAnnotation:(id)ann{
    [map selectAnnotation:ann animated:NO];
}
-(id<MKAnnotation>)annotationsForCoordinate:(CLLocationCoordinate2D)newLocation {
    LWSAnnotation* annotation = [[LWSAnnotation alloc] init];
    annotation.coordinate = newLocation;
    annotation.title = [NSString stringWithFormat:@"%d", [anotations count]];
    return annotation;
}
-(id<MKAnnotation>)addNewAnnotationForCoordinate:(CLLocationCoordinate2D)newLocation {
    LWSAnnotation* annotation = [self annotationsForCoordinate:newLocation];
    
    [anotations addObject:annotation];
    [map addAnnotation:annotation];
    return annotation;
}
-(void)addToRoutePointsPath:(NSArray*)paths ForUserInfo:(id)userinfoArg {
    int indexCurrentPath = [anotations indexOfObject:userinfoArg];
    NSArray* annRouteArr = nil;
    for (int i = indexCurrentPath-1; i>=0; --i) {
        annRouteArr = [routeForAnnotationPoints objectForKey:anotations[i]];
        if (annRouteArr) {
            break;
        }
    }
    if (annRouteArr) {
        if ([annRouteArr count] > 0) {
            NSValue* val = [annRouteArr lastObject];
            int endIndex = [routePoints indexOfObject:val];
            
            [routePoints insertObjects:paths atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(endIndex+1, [paths count])]];
        }
    }
    else {
        [routePoints addObjectsFromArray:paths];
    }
}

-(void)updateRouteForPoints:(NSArray*)arr UserInfo:(id)ann {
    NSMutableArray* stringArray = [NSMutableArray array];
    for (int i = 0; i < [arr count]; ++i) {
        id<MKAnnotation> item = arr[i];
        CLLocationCoordinate2D coordinate = [item coordinate];
        
        NSString *positionString = [[NSString alloc] initWithFormat:@"%f,%f",
                                    coordinate.latitude,coordinate.longitude];
        [stringArray addObject:positionString];
    }
    if (!directionService) {
        directionService = [[LWSDirectionService alloc] init];
        directionService.delegate = self;
    }
    [directionService loadDirectionsForLocationsStrings:stringArray userInfo:ann];
}

#pragma mark - LWSDirectionServiceDelegate

-(void)directionReceived:(LWSDirectionService*)sender Data:(NSArray*)paths userInfo:(id)userinfoArg {
    self.isLoadingRoute = NO;
    if ([paths count] > 1) {
        if ([self.delegate respondsToSelector:@selector(routeCreated)]) {
            [self.delegate routeCreated];
        }
        if ([self.delegate respondsToSelector:@selector(routeLoaded)]) {
            [self.delegate routeLoaded];
        }
        
        if ([routeForAnnotationPoints objectForKey:userinfoArg]) {
            [routeForAnnotationPoints removeObjectForKey:userinfoArg];
        }
        [routeForAnnotationPoints setObject:paths forKey:userinfoArg];
        [self addToRoutePointsPath:paths ForUserInfo:userinfoArg];
        MKMapPoint* points = malloc(sizeof(MKMapPoint)*[paths count]);
        for (int i = 0; i < [paths count]; ++i) {
            NSValue* item = paths[i];
            CLLocationCoordinate2D coord = [item MKCoordinateValue];
            MKMapPoint point = MKMapPointForCoordinate(coord);
            points[i] = point;
        }
        MKPolyline* mainPolyline = [MKPolyline polylineWithPoints:points count:[paths count]];
        mainPolyline.title = @"mainPolyline";
        [map addOverlay:mainPolyline];
        if ([routePolylines objectForKey:userinfoArg]) {
            [routePolylines removeObjectForKey:userinfoArg];
        }
        [routePolylines setObject:mainPolyline forKey:userinfoArg];
    }
}
-(void)directionReceivedFailed:(LWSDirectionService*)sender Data:(NSArray*)paths userInfo:(id)userinfoArg {
    self.isLoadingRoute = NO;
    if ([paths count] > 1) {
        if ([self.delegate respondsToSelector:@selector(routeCreated)]) {
            [self.delegate routeCreated];
        }
        if ([self.delegate respondsToSelector:@selector(routeLoadedError)]) {
            [self.delegate routeLoadedError];
        }
        if (!routePolylines) {
            routePolylines = [NSMutableDictionary dictionary];
        }
        if (!routePoints) {
            routePoints = [NSMutableArray array];
        }
        if (!routeForAnnotationPoints) {
            routeForAnnotationPoints = [NSMutableDictionary dictionary];
        }
        
        if ([routeForAnnotationPoints objectForKey:userinfoArg]) {
            [routeForAnnotationPoints removeObjectForKey:userinfoArg];
        }
        [routeForAnnotationPoints setObject:paths forKey:userinfoArg];
        [self addToRoutePointsPath:paths ForUserInfo:userinfoArg];
        MKMapPoint* points = malloc(sizeof(MKMapPoint)*[paths count]);
        for (int i = 0; i < [paths count]; ++i) {
            NSValue* item = paths[i];
            CLLocationCoordinate2D coord = [item MKCoordinateValue];
            MKMapPoint point = MKMapPointForCoordinate(coord);
            points[i] = point;
        }
        MKPolyline* failedPolyline = [MKPolyline polylineWithPoints:points count:[paths count]];
        failedPolyline.title = @"failedPolyline";
        [map addOverlay:failedPolyline];
        if ([routePolylines objectForKey:userinfoArg]) {
            [routePolylines removeObjectForKey:userinfoArg];
        }
        [routePolylines setObject:failedPolyline forKey:userinfoArg];
    }
}

#pragma mark - MapKit

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if([overlay class] == MKPolyline.class)
    {
        MKOverlayView* overlayView = nil;
        MKPolyline* polyline = (MKPolyline *)overlay;
        MKPolylineView  * routeLineView = [[MKPolylineView alloc] initWithPolyline:polyline];
        if ([[overlay title] isEqualToString:@"mainPolyline"]) {
            routeLineView.lineWidth = 4;
            routeLineView.fillColor = [UIColor redColor];
            routeLineView.strokeColor = [UIColor redColor];
            routeLineView.lineCap = kCGLineCapSquare;
            routeLineView.layer.zPosition = 1000;
        }
        else if ([[overlay title] isEqualToString:@"failedPolyline"]) {
            routeLineView.lineWidth = 4;
            routeLineView.fillColor = [UIColor lightGrayColor];
            routeLineView.strokeColor = [UIColor lightGrayColor];
            routeLineView.layer.zPosition = 1000;
            routeLineView.lineCap = kCGLineCapSquare;
            routeLineView.lineDashPhase = 5;
            NSArray* array = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], [NSNumber numberWithInt:5], nil];
            routeLineView.lineDashPattern = array;
            
        }
        overlayView = routeLineView;
        return overlayView;
    } else {
        return nil;
    }
}
- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
	}
    
    MKAnnotationView* annView  = nil;// = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:annotation];
    
    if (!annView) {
        if ([annotation isKindOfClass:[LWSAnnotation class]]) {
            //MKAnnotationView* annView;//  = [theMapView dequeueReusableAnnotationViewWithIdentifier:[(LWSAnnotation*)annotation title]];
            if (![[annotation title] isEqualToString:@"Scene position"] && [self.anotations containsObject:annotation]) {
                annView=[LWSAnnotationView annotationViewWithAnnotation:annotation reuseIdentifier:[(LWSAnnotation*)annotation title] mapView:map];
                //                [self setAnotationsViewAsSimple:annView];
                [(LWSAnnotation*)annotation setAnnotationView:annView];
                [annView setDraggable:self.isCanEditRouteEnable];
                [annView setCanShowCallout:NO];
                [self performSelector:@selector(updateAnnotations) withObject:nil afterDelay:0.001];
            }
            else if (annotation == currentVideoPlace) {
                annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[(LWSAnnotation*)annotation title]];
                [(LWSAnnotation*)annotation setAnnotationView:annView];
                [annView setDraggable:NO];
                annView.image = [UIImage imageNamed:@"dot_play.png"];
                [annView setCanShowCallout:NO];
            }
        }
        
    }
    return annView;
}
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[LWSAnnotation class]]) {
        if (![[view.annotation title] isEqualToString:@"Scene position"]) {
            [view setSelected:YES];
            if ([self.delegate respondsToSelector:@selector(annotationIsDeseleceted:)]) {
                [self.delegate annotationIsDeseleceted:view.annotation];
            }
        }
    }
}
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[LWSAnnotation class]]) {
        if (![[view.annotation title] isEqualToString:@"Scene position"]) {
            if ([self.delegate respondsToSelector:@selector(annotationIsSeleceted:)]) {
                [self.delegate annotationIsSeleceted:view.annotation];
            }
        }
    }
}
-(void)removeArray:(NSArray*)arrForDelete fromArray:(NSMutableArray*)arrFromDeleteArg {
    NSMutableIndexSet* indaxesArr = [NSMutableIndexSet indexSet];
    NSArray* arrFromDelete = [NSMutableArray arrayWithArray:arrFromDeleteArg];
    for (int i = 0; i < [arrFromDelete count]; ++i) {
        id itemFrom = arrFromDelete[i];
        for (int j = 0; j < [arrForDelete count]; ++j) {
            id itemFor = arrForDelete[j];
            if (itemFrom == itemFor) {
                [indaxesArr addIndex:i];
                break;
            }
        }
    }
    [arrFromDeleteArg removeObjectsAtIndexes:indaxesArr];
}

-(id)selectedAnotation {
    for (LWSAnnotation* ann in anotations) {
        if ([map.selectedAnnotations containsObject:ann]) {
            return ann;
        }
    }
    return nil;
}
-(void)deleteRouteAnnotations:(id<MKAnnotation>)annArg NeedUpdate:(BOOL)needUpdateArg {
    if (self.isCanEditRouteEnable) {
        [self deleteRoutesForAnnotation:annArg NeedUpdate:NO];
        [directionService stopLoadingForUserInfo:annArg];
        
        int indexAnn = [anotations indexOfObject:annArg];
        if (needUpdateArg) {
            if ([anotations count] > 2) {
                if (indexAnn == 0) {
                }
                else if (indexAnn == [anotations count] - 1) {
                    if ([self.delegate respondsToSelector:@selector(routeLoaded)]) {
                        [self.delegate routeLoaded];
                    }
                }
                else {
                    [self updateRouteForPoints:[NSArray arrayWithObjects:anotations[indexAnn - 1],anotations[indexAnn + 1], nil] UserInfo:anotations[indexAnn + 1]];
                }
            }
        }
        
        
        [map removeAnnotation:annArg];
        [anotations removeObject:annArg];
        
        if ([anotations count] > 0) {
            if (indexAnn > 0) {
                --indexAnn;
            }
            [map selectAnnotation:anotations[indexAnn] animated:NO];
        }
        
        
        
        if ([anotations count] < 2) {
            if ([self.delegate respondsToSelector:@selector(routeDestroyed)]) {
                [self.delegate routeDestroyed];
            }
        }
        [self updateAnnotations];
    }
}
-(void)deleteRoutesForAnnotation:(id<MKAnnotation>)annArg NeedUpdate:(BOOL)needUpdateArg {
    if ([anotations count] > 1) {
        int indexAnn = [anotations indexOfObject:annArg];
        if (indexAnn == 0) {
            NSArray* routeForAnnotationPointsArr = [routeForAnnotationPoints objectForKey:anotations[indexAnn + 1]];
            [self removeArray:routeForAnnotationPointsArr fromArray:routePoints];
            [routeForAnnotationPoints removeObjectForKey:anotations[indexAnn + 1]];
            id<MKOverlay> polyline = [routePolylines objectForKey:anotations[indexAnn + 1]];
            [routePolylines removeObjectForKey:anotations[indexAnn + 1]];
            [map removeOverlay:polyline];
            
            if (needUpdateArg) {
                [self updateRouteForPoints:[NSArray arrayWithObjects:annArg,anotations[indexAnn + 1], nil] UserInfo:anotations[indexAnn + 1]];
            }
        }
        else if (indexAnn == [anotations count] - 1) {
            NSArray* routeForAnnotationPointsArr = [routeForAnnotationPoints objectForKey:annArg];
            [self removeArray:routeForAnnotationPointsArr fromArray:routePoints];
            [routeForAnnotationPoints removeObjectForKey:annArg];
            id<MKOverlay> polyline = [routePolylines objectForKey:annArg];
            [routePolylines removeObjectForKey:annArg];
            [map removeOverlay:polyline];
            
            if (needUpdateArg) {
                [self updateRouteForPoints:[NSArray arrayWithObjects:anotations[indexAnn - 1],annArg, nil] UserInfo:annArg];
            }
        }
        else {
            NSArray* routeForAnnotationPointsArr = [routeForAnnotationPoints objectForKey:annArg];
            [self removeArray:routeForAnnotationPointsArr fromArray:routePoints];
            [routeForAnnotationPoints removeObjectForKey:annArg];
            routeForAnnotationPointsArr = [routeForAnnotationPoints objectForKey:anotations[indexAnn + 1]];
            [self removeArray:routeForAnnotationPointsArr fromArray:routePoints];
            [routeForAnnotationPoints removeObjectForKey:anotations[indexAnn + 1]];
            
            id<MKOverlay> polyline = [routePolylines objectForKey:annArg];
            [routePolylines removeObjectForKey:annArg];
            [map removeOverlay:polyline];
            polyline = [routePolylines objectForKey:anotations[indexAnn + 1]];
            [routePolylines removeObjectForKey:anotations[indexAnn + 1]];
            [map removeOverlay:polyline];
            
            if (needUpdateArg) {
                [self updateRouteForPoints:[NSArray arrayWithObjects:anotations[indexAnn - 1],annArg, nil] UserInfo:annArg];
                [self updateRouteForPoints:[NSArray arrayWithObjects:anotations[indexAnn],anotations[indexAnn + 1], nil] UserInfo:anotations[indexAnn + 1]];
            }
        }
    }
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if ([annotationView.annotation isKindOfClass:[LWSAnnotation class]]) {
        if (newState == MKAnnotationViewDragStateEnding) {
            
            [self deleteRoutesForAnnotation:annotationView.annotation NeedUpdate:YES];
        }
        else if (newState == MKAnnotationViewDragStateStarting) {
        }
    }
}


@end
