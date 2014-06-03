//
//  PanoLoader.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 01.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "PanoLoader.h"
#import "PanoPoint.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AFNetworking.h>
#import <SDWebImageManager.h>

@interface PanoLoader ()  {
    BOOL isStartLoading;
    AFHTTPRequestOperationManager *manager;
    AFHTTPRequestOperation* request;
    
    UIBackgroundTaskIdentifier bgTask;
}
@end
@implementation PanoLoader
@synthesize delegate,loadedImages,coordArr,currentCoordArrIndex,averageDownloadSpeed,averagePackageSize,allPackageSize,isStopedLoadingPano;
-(void)stopLoadingImages {
    isStartLoading = NO;
    [request cancel];
    isStopedLoadingPano = YES;
    [self.delegate allImagesLoaded:self.loadedImages];
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

double distanceBetweenTwoCoord(CLLocationCoordinate2D loc1,CLLocationCoordinate2D loc2) {
    double r_earth = 6378130.2;
    
    double cl1 = cos(loc1.latitude);
    double cl2 = cos(loc2.latitude);
    double sl1 = sin(loc1.latitude);
    double sl2 = sin(loc2.latitude);
    double delta = loc2.longitude - loc1.longitude;
    double cdelta = cos(delta);
    double sdelta = sin(delta);
    
    //вычисления длины большого круга
    double y = sqrt(pow(cl2*sdelta,2)+pow(cl1*sl2-sl1*cl2*cdelta,2));
    double x = sl1*sl2+cl1*cl2*cdelta;
    double ad = atan2(y,x);
    double distance = ad*r_earth;
    
    return distance;
}
CLLocationCoordinate2D pointOnLine(double t, CLLocationCoordinate2D a,CLLocationCoordinate2D b) {
    double toRad = M_PI/180.0;
    double toDeg = 180.0/M_PI;
    
	CLLocationDegrees x = a.latitude*toRad + t * (b.latitude*toRad - a.latitude*toRad);
	CLLocationDegrees y = a.longitude*toRad + t * (b.longitude*toRad - a.longitude*toRad);
    
    return CLLocationCoordinate2DMake(x*toDeg, y*toDeg);
}
-(NSMutableArray*)arrayForPanoramo:(NSArray*)routePoints {
    NSMutableArray* locationsArr = [NSMutableArray array];
    double d = 0;
    double r = 0;
    double _d = 0;
    double total_distance = 0;
    double _distance_between_points = 500.0;
    for (int i = 0; i < routePoints.count-1; ++i) {
        CLLocationCoordinate2D a = [routePoints[i] MKCoordinateValue];
        CLLocationCoordinate2D b = [routePoints[i+1] MKCoordinateValue];
        total_distance += distanceBetweenTwoCoord(a,b);
    }
    
    double _max_points = 200;
    double segment_length = total_distance/_max_points;
    _d = (segment_length < _distance_between_points) ? _distance_between_points : segment_length;
    
    for (int i = 0; i < routePoints.count; ++i) {
        if(i+1 < routePoints.count) {
            CLLocationCoordinate2D a = [routePoints[i] MKCoordinateValue];
            CLLocationCoordinate2D b = [routePoints[i+1] MKCoordinateValue];
            d = distanceBetweenTwoCoord(a, b);
            if(r > 0 && r < d) {
                a = pointOnLine(r/d, a, b);
                d = distanceBetweenTwoCoord(a, b);
                [locationsArr addObject:[NSValue valueWithMKCoordinate:a]];
                
                r = 0;
            } else if(r > 0 && r > d) {
                r -= d;
            }
            if(r == 0) {
                double segs = floor(d/_d);
                
                if(segs > 0) {
                    for(int j=0; j<segs; j++) {
                        double t = j/segs;
                        
                        if( t>0 || (t+i)==0  ) { // not start point
                            CLLocationCoordinate2D way = pointOnLine(t, a, b);
                            [locationsArr addObject:[NSValue valueWithMKCoordinate:way]];
                        }
                    }
                    
                    r = d-(_d*segs);
                } else {
                    r = _d*( 1-(d/_d) );
                }
            }
            
            
        }
        else {
            CLLocationCoordinate2D a = [routePoints[i] MKCoordinateValue];
            [locationsArr addObject:[NSValue valueWithMKCoordinate:a]];
        }
    }
    return locationsArr;
}
-(id)init {
    if (self = [super init]) {
        loadedImages = [NSMutableArray array];
    }
    return self;
}

-(NSData*)imgByPath:(NSString*)path {
    NSURL *url = [NSURL URLWithString:path];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    url = nil;
    return data;
}
-(void)loadForCoordinatesArray:(NSArray*)arg {
    @try {
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        isStartLoading = YES;
        averageDownloadSpeed = 0;
        averagePackageSize = 0;
        allPackageSize = 0;
        [self.loadedImages removeAllObjects];
        currentCoordArrIndex = 0;
        coordArr = [self arrayForPanoramo:arg];
        CLLocationCoordinate2D strCoord = [self getCoordForIndex:currentCoordArrIndex];
        [self loadMyWebViewForCoord:strCoord];
    }
    @catch (NSException* ex) {
    }
}
-(CLLocationCoordinate2D)getCoordForIndex:(int)index {
    CLLocationCoordinate2D coords = [((NSValue*)coordArr[index]) MKCoordinateValue];
    return coords;
}
-(void)loadPanoIDError {
    if (currentCoordArrIndex < [coordArr count]) {
        [coordArr removeObjectAtIndex:currentCoordArrIndex];
    }
    [self.delegate loaderProcess:((double)currentCoordArrIndex)/((double)coordArr.count) withPanoPoint:nil isFirstImages:NO];
    //    ++currentCoordArrIndex;
    if (currentCoordArrIndex >=coordArr.count || !isStartLoading) {
        if (isStartLoading) {
            isStopedLoadingPano = NO;
        }
        [self.delegate allImagesLoaded:self.loadedImages];
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
    else {
        [self moveStreetViewToNextPoint];
    }
}
-(BOOL)isContainPano:(PanoPoint*)arg {
    BOOL res = NO;
    if ([self.loadedImages count] > 0) {
        //    for (PanoPoint* item in self.loadedImages) {
        PanoPoint* item = [self.loadedImages lastObject];
        if ([arg.panoID isEqualToString:item.panoID]) {
            res = YES;
            //                break;
        }
        //    }
    }
    
    return res;
}

-(void)loadMyWebViewForCoord:(CLLocationCoordinate2D)arg{
    @try {
        if (!manager) {
            manager = [AFHTTPRequestOperationManager manager];
        }
        
        NSString* urlStr = [NSString stringWithFormat:@"http://cbk0.google.com/cbk?output=json&ll=%f,%f",arg.latitude,arg.longitude];
        request = [manager GET:urlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (!isStartLoading) {
                isStartLoading = NO;
                [self.delegate allImagesLoaded:self.loadedImages];
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
                return;
            }
            id location = [responseObject objectForKey:@"Location"];
            id projection = [responseObject objectForKey:@"Projection"];
            if (location && projection) {
                PanoPoint* currentPanoPoint = [[PanoPoint alloc] init];
                currentPanoPoint.panoID = [location objectForKey:@"panoId"];
                if (![self isContainPano:currentPanoPoint]) {
                    currentPanoPoint.coordinates = arg;
                    currentPanoPoint.elevation = [[location objectForKey:@"elevation_wgs84_m"] doubleValue];
                    currentPanoPoint.pitch = [[projection objectForKey:@"tilt_pitch_deg"] doubleValue];
                    currentPanoPoint.heading = [[projection objectForKey:@"pano_yaw_deg"] doubleValue];
                    currentPanoPoint.tiltHeading = [[projection objectForKey:@"tilt_yaw_deg"] doubleValue];
                    
                    if (currentCoordArrIndex >=coordArr.count) {//coordArr.count
                        if (isStartLoading) {
                            isStopedLoadingPano = NO;
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
                            [self.delegate allImagesLoaded:self.loadedImages];
                            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                            bgTask = UIBackgroundTaskInvalid;
                        }];
                        isStartLoading = NO;
                    }
                    else {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            @autoreleasepool {
                                if (!isStartLoading) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
                                        [self.delegate allImagesLoaded:self.loadedImages];
                                        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                                        bgTask = UIBackgroundTaskInvalid;
                                    }];
                                    return;
                                }
                                [self loadImagesForPanoPoint:currentPanoPoint];
                                [self.loadedImages addObject:currentPanoPoint];
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
                                    ++currentCoordArrIndex;
                                    
                                    [self.delegate loaderProcess:((double)currentCoordArrIndex)/((double)coordArr.count) withPanoPoint:currentPanoPoint isFirstImages:(currentCoordArrIndex == 1)];
                                    if (currentCoordArrIndex >=coordArr.count || !isStartLoading) {
                                        if (isStartLoading) {
                                            isStopedLoadingPano = NO;
                                        }
                                        isStartLoading = NO;
                                        [self.delegate allImagesLoaded:self.loadedImages];
                                        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                                        bgTask = UIBackgroundTaskInvalid;
                                    }
                                    else {
                                        [self moveStreetViewToNextPoint];
                                    }
                                }];
                            }
                        });
                    }
                }
                else {
                    [self loadPanoIDError];
                }
            }
            else {
                [self loadPanoIDError];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self loadPanoIDError];
        }];
    }
    @catch (NSException* ex) {
    }
}

-(void)loadImagesForPanoPoint:(PanoPoint*)currentPanoPointArg {
    @try {
        NSMutableArray* imForCurrentCoord = [NSMutableArray array];
        NSMutableArray* imForCurrentCoordTemp = [NSMutableArray array];
        NSMutableArray* imForCurrentCoordV = [NSMutableArray array];
        __block double pakSize = 0.0;
        double downLoadTime = 0.0;
        double startSec = [[NSDate date] timeIntervalSince1970];
        int zoom;
        int maxX;
        int maxY;
        zoom = 3;
        maxX = 7;
        maxY = 3;
        __block int allImages = maxX;
        for (int x = 0; x < maxX; ++x) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSMutableArray* imForCurrentCoodY = [NSMutableArray array];
                for (int y = 0; y < maxY; ++y) {
                    @autoreleasepool {
                        NSString* pathStr = [NSString stringWithFormat:@"http://cbk0.google.com/cbk?output=tile&panoid=%@&zoom=%d&x=%d&y=%d",currentPanoPointArg.panoID,zoom,x,y];
                        NSString* tempDirectory = NSTemporaryDirectory();
                        NSString* imPath = [NSString stringWithFormat:@"%@/panoLoadCash/%@zoom=%dx=%dy=%d_%d",tempDirectory,currentPanoPointArg.panoID,zoom,x,y,currentCoordArrIndex];
                        NSData* im = nil;
                        NSFileManager* fM = [NSFileManager defaultManager];
                        BOOL isD;
                        if (![fM fileExistsAtPath:imPath isDirectory:&isD]) {
                            im = [self imgByPath:pathStr];
                        }
                        else {
                            [imForCurrentCoodY addObject:imPath];
                        }
                        if (im) {
                            pakSize += im.length;
                            if (![fM fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingString:@"panoLoadCash"] isDirectory:&isD]) {
                                NSError* err;
                                [fM createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingString:@"panoLoadCash"] withIntermediateDirectories:YES attributes:[NSDictionary dictionary] error:&err];
                            }
                            [im writeToFile:imPath atomically:YES];
                            
                            [imForCurrentCoodY addObject:imPath];
                        }
                    }
                }
                [imForCurrentCoordV addObject:@(x)];
                [imForCurrentCoordTemp addObject:imForCurrentCoodY];
                --allImages;
            });
        }
        while (allImages) {
            sleep(0.001);
        }
        for (int x = 0; x < maxX; ++x) {
            if ([imForCurrentCoordV containsObject:@(x)]) {
                int index = [imForCurrentCoordV indexOfObject:@(x)];
                [imForCurrentCoord addObject:imForCurrentCoordTemp[index]];
            }
        }
        [imForCurrentCoordTemp removeAllObjects];
        double endSec = [[NSDate date] timeIntervalSince1970];
        downLoadTime = endSec - startSec;
        currentPanoPointArg.imageFilePaths = imForCurrentCoord;
        allPackageSize += pakSize;
        self.averagePackageSize = (self.averagePackageSize+pakSize)/2;
        //    self.averageDownloadSpeed = (self.averageDownloadSpeed+downLoadTime)/2;
        self.averageDownloadSpeed = downLoadTime;
    }
    @catch (NSException* ex) {
    }
}
-(void)moveStreetViewToNextPoint {
    if (currentCoordArrIndex < coordArr.count) {
        CLLocationCoordinate2D strCoord = [self getCoordForIndex:currentCoordArrIndex];
        
        [self loadMyWebViewForCoord:strCoord];
    }
}
@end
