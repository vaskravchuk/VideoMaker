//
//  LWSMapVIewMultiplyDelegate.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 05.12.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "LWSMapViewMultiplyDelegate.h"
#import <MapKit/MapKit.h>

@interface LWSMapViewMultiplyDelegate () <MKMapViewDelegate> {
    NSMutableArray* delegates;
}

@end

@implementation LWSMapViewMultiplyDelegate
@synthesize map;
-(void)setMap:(MKMapView *)mapArg {
    map = mapArg;
    map.delegate = self;
}
-(MKMapView*)map {
    return map;
}

-(void)setMapViewDelegate:(id)arg {
    if (!delegates) {
        delegates = [NSMutableArray array];
    }
    if (![delegates containsObject:arg]) {
        [delegates addObject:arg];
    }
}

-(void)removeMapViewDelegate:(id)arg {
    if (delegates && [delegates containsObject:arg]) {
        [delegates removeObject:arg];
    }
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]) {
            [delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
        }
    }
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)]) {
            [delegate mapView:mapView annotationView:annotationView didChangeDragState:newState fromOldState:oldState];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
            [delegate mapView:mapView didAddAnnotationViews:views];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didAddOverlayRenderers:(NSArray *)renderers {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didAddOverlayRenderers:)]) {
            [delegate mapView:mapView didAddOverlayRenderers:renderers];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)]) {
            [delegate mapView:mapView didChangeUserTrackingMode:mode animated:animated];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)]) {
            [delegate mapView:mapView didDeselectAnnotationView:view];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)]) {
            [delegate mapView:mapView didFailToLocateUserWithError:error];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
            [delegate mapView:mapView didSelectAnnotationView:view];
        }
    }
}
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
            [delegate mapView:mapView didUpdateUserLocation:userLocation];
        }
    }
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
            [delegate mapView:mapView regionDidChangeAnimated:animated];
        }
    }
}
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
            [delegate mapView:mapView regionWillChangeAnimated:animated];
        }
    }
}
//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
//    for (id<MKMapViewDelegate> delegate in delegates) {
//        if ([delegate respondsToSelector:@selector(mapView:rendererForOverlay:)]) {
//            MKOverlayRenderer *overlayRenderer = [delegate mapView:mapView rendererForOverlay:overlay];
//            if (overlayRenderer) {
//                return overlayRenderer;
//            }
//        }
//    }
//    return nil;
//}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            MKAnnotationView *annotationView = [delegate mapView:mapView viewForAnnotation:annotation];
            if (annotationView) {
                return annotationView;
            }
        }
    }
    return nil;
}
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)]) {
            [delegate mapViewDidFailLoadingMap:mapView withError:error];
        }
    }
}
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)]) {
            [delegate mapViewDidFinishLoadingMap:mapView];
        }
    }
}
- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)]) {
            [delegate mapViewDidFinishRenderingMap:mapView fullyRendered:fullyRendered];
        }
    }
}
- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)]) {
            [delegate mapViewDidStopLocatingUser:mapView];
        }
    }
}
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)]) {
            [delegate mapViewWillStartLoadingMap:mapView];
        }
    }
}
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)]) {
            [delegate mapViewWillStartLocatingUser:mapView];
        }
    }
}
- (void)mapViewWillStartRenderingMap:(MKMapView *)mapView {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)]) {
            [delegate mapViewWillStartRenderingMap:mapView];
        }
    }

}
- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)]) {
            [delegate mapView:mapView didAddOverlayViews:overlayViews];
        }
    }
}
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id < MKOverlay >)overlay {
    for (id<MKMapViewDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(mapView:viewForOverlay:)]) {
            MKOverlayView *overlayView = [delegate mapView:mapView viewForOverlay:overlay];
            if (overlayView) {
                return overlayView;
            }
        }
    }
    return nil;
    
}

@end
