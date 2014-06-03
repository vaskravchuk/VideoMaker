//
//  LWSDirectionService.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 01.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "LWSDirectionService.h"
#import <AFNetworking.h>
#import <MapKit/MapKit.h>
#import <GoogleMaps.h>

@interface LWSDirectionService () {
    AFHTTPRequestOperationManager *manager;
    NSMutableDictionary * requestOperations;
    NSArray *waypoints;
}
@end

@implementation LWSDirectionService{
  @private
  BOOL _sensor;
  BOOL _alternatives;
  NSURL *_directionsURL;
}

static NSString *kLWSDirectionsURL = @"http://maps.googleapis.com/maps/api/directions/json?";

- (void)loadDirectionsForLocationsStrings:(NSArray *)locationsStrings userInfo:(id)userinfoArg{
    @try {
        waypoints = locationsStrings;
        NSString *origin = [waypoints objectAtIndex:0];
        int waypointCount = [waypoints count];
        int destinationPos = waypointCount -1;
        NSString *destination = [waypoints objectAtIndex:destinationPos];
        NSString *sensor = @"false";
        NSMutableString *url = [NSMutableString stringWithFormat:@"%@&origin=%@&destination=%@&sensor=%@",
        kLWSDirectionsURL,origin,destination, sensor];
        if(waypointCount>2) {
        [url appendString:@"&waypoints=optimize:true"];
        int wpCount = waypointCount-2;
        for(int i=1;i<wpCount;i++){
          [url appendString: @"|"];
          [url appendString:[waypoints objectAtIndex:i]];
        }
        }
        url = [NSMutableString stringWithString:[url stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]];
        _directionsURL = [NSURL URLWithString:url];

        [self startDownloadDataForURL:_directionsURL userInfo:userinfoArg];
    }
    @catch (NSException* ex) {
    }
}

-(CLLocationCoordinate2D)coordFormString:(NSString*)arg {
    NSArray* substrs = [arg componentsSeparatedByString:@","];
    CLLocationCoordinate2D coord;
    if (substrs.count > 1) {
        coord.latitude = [substrs[0] doubleValue];
        coord.longitude = [substrs[1] doubleValue];
    }
    return coord;
}
-(void)startDownloadDataForURL:(NSURL*)url userInfo:(id)userinfoArg {
    @try {
        if (!manager) {
            manager = [AFHTTPRequestOperationManager manager];
        }
        if (!requestOperations) {
            requestOperations = [NSMutableDictionary dictionary];
        }
        __weak id userInfo = userinfoArg;
        [self stopLoadingForUserInfo:userInfo];
        AFHTTPRequestOperation *requestOperation = [manager GET:[url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (userInfo && [requestOperations objectForKey:userInfo]) {
                [requestOperations removeObjectForKey:userInfo];
                NSString* status = [responseObject objectForKey:@"status"];
                NSArray* routesArr = [responseObject objectForKey:@"routes"];
                if ([status isEqualToString:@"OK"] && [routesArr count] > 0) {
                    NSDictionary *routes = [responseObject objectForKey:@"routes"][0];
                    
                    NSDictionary *route = [routes objectForKey:@"overview_polyline"];
                    NSString *overview_route = [route objectForKey:@"points"];
                    GMSPath *path = [GMSPath pathFromEncodedPath:overview_route];
                    
                    NSMutableArray* coordinatesArr = [NSMutableArray array];
                    for (int i = 0; i < [path count]; ++i) {
                        CLLocationCoordinate2D coord = [path coordinateAtIndex:i];
                        
                        [coordinatesArr addObject:[NSValue valueWithMKCoordinate:coord]];
                    }
                    
                    if ([self.delegate respondsToSelector:@selector(directionReceived:Data:userInfo:)]) {
                        [self.delegate directionReceived:self Data:coordinatesArr userInfo:userInfo];
                    }
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(directionReceivedFailed:Data:userInfo:)]) {
                        NSMutableArray* coordinatesArr = [NSMutableArray array];
                        for (int i = 0; i < [waypoints count]; ++i) {
                            CLLocationCoordinate2D coord = [self coordFormString:waypoints[i]];
                            [coordinatesArr addObject:[NSValue valueWithMKCoordinate:coord]];
                        }
                        [self.delegate directionReceivedFailed:self Data:coordinatesArr userInfo:userInfo];
                    }
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (userInfo && [requestOperations objectForKey:userInfo] && !operation.isCancelled) {
                [requestOperations removeObjectForKey:userInfo];
                if ([self.delegate respondsToSelector:@selector(directionReceivedFailed:Data:userInfo:)]) {
                    NSMutableArray* coordinatesArr = [NSMutableArray array];
                    for (int i = 0; i < [waypoints count]; ++i) {
                        CLLocationCoordinate2D coord = [self coordFormString:waypoints[i]];
                        [coordinatesArr addObject:[NSValue valueWithMKCoordinate:coord]];
                    }
                    [self.delegate directionReceivedFailed:self Data:coordinatesArr userInfo:userInfo];
                }
            }
        }];
        
        [requestOperations setObject:requestOperation forKey:userInfo];
    }
    @catch (NSException* ex) {
    }
}

- (void)stopLoadingForUserInfo:(id)userinfoArg {
    @try {
        AFHTTPRequestOperation *requestOperation = [requestOperations objectForKey:userinfoArg];
        if (requestOperation) {
            [requestOperation cancel];
            [requestOperations removeObjectForKey:userinfoArg];
        }
    }
    @catch (NSException* ex) {
    }
}
- (void)stopLoading {
    @try {
        for (AFHTTPRequestOperation *requestOperation in [requestOperations allValues]) {
            [requestOperation cancel];
        }
        [requestOperations removeAllObjects];
        
    }
    @catch (NSException* ex) {
    }
}

@end
