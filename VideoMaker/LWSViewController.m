//
//  LWSViewController.m
//  VideoMaker
//
//  Created by Василий Кравчук on 28.05.14.
//  Copyright (c) 2014 lifewaresolutions. All rights reserved.
//

#import "LWSViewController.h"
#import <MapKit/MapKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VideoManager.h"
#import "RouteManager.h"
#import "PanoLoader.h"
#import <AudioToolbox/AudioServices.h>
#import "InfiniteImageScrollView.h"
#import "BackgroundTaskManager.h"

@interface LWSViewController () <UIGestureRecognizerDelegate,VideoManagerDelegate,RouteManagerDelegate,PanoLoaderDelegate,InfiniteImageScrollViewDelegate> {
    __weak IBOutlet UIProgressView *progressBar;
    __weak IBOutlet MKMapView *mapView;
    __weak IBOutlet UIBarButtonItem *createVideoButton;
    __weak IBOutlet UIView *scrContainer;
    NSMutableArray* imagesPathArr;
    MPMoviePlayerViewController *playercontroller;
    VideoManager* videoManager;
    LWSMapViewMultiplyDelegate* mapViewMultiplyDelegate;
    
    RouteManager* routeManager;
    PanoLoader* panoLoader;
    
    InfiniteImageScrollView* streetImageView;
    
    UITapGestureRecognizer* tapRec;
    NSOperationQueue* loadingVideoQueue;
}
@end

@implementation LWSViewController

-(UIImage*)scrImageRef {
    UIGraphicsBeginImageContextWithOptions([scrContainer frame].size, YES, 2);
    [[scrContainer layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return viewImage;
}
-(int)scenesCount {
    return [panoLoader.coordArr count]-1;
}
-(void)saveVideo {
    //start generating video from screenshoots path that we created early
    [videoManager startCreationVideoForImages:imagesPathArr];
}
-(void)createScrForCurrentIndex {
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    [operation addExecutionBlock:^{
        int oldIndex = streetImageView.imagesCurentIndex;
        @autoreleasepool {
            UIImage *image = [self scrImageRef]; // get screenshoot from streetImageView
            if (image)
            {
                NSFileManager* fM = [NSFileManager defaultManager];
                BOOL isD;
                if (![fM fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingString:@"VideoScrCash"] isDirectory:&isD]) {
                    NSError* err;
                    [fM createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingString:@"VideoScrCash"] withIntermediateDirectories:YES attributes:[NSDictionary dictionary] error:&err];
                }
                [imagesPathArr addObject:[NSTemporaryDirectory() stringByAppendingFormat:@"VideoScrCash/scrForVideo%d.png",streetImageView.imagesCurentIndex]];
                //save screenshoot in tmp/VideoScrCash/scrForVideo%d.png folder
                [UIImagePNGRepresentation(image) writeToFile:[imagesPathArr lastObject] atomically:YES];
            }
            double per = (double)streetImageView.imagesCurentIndex / (double)[self scenesCount];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
                progressBar.progress = per;
            }];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
                [streetImageView nextScene];
                // If all screenshoot created
                if ([streetImageView isEndScene] && (oldIndex == streetImageView.imagesCurentIndex)) {
                    [self saveVideo]; //End Geting screenhoots
                }
                else {
                    [self createScrForCurrentIndex]; //Go To the nex pano scene for rotate it
                }
            }];
        }
    }];
    [loadingVideoQueue addOperation:operation];
}
-(void)allImagesLoaded:(NSArray*)resArrArg {
    if (!loadingVideoQueue) {
        loadingVideoQueue = [[NSOperationQueue alloc] init];
    }
    [streetImageView setImagesArrForAnimating:panoLoader.loadedImages];
    [imagesPathArr removeAllObjects];
    
    //Start Creating screnshoot from streetImageView for pano that rotated in the direction of motion
    [self createScrForCurrentIndex];
}
-(void)loaderProcess:(double)per withPanoPoint:(PanoPoint*)arg isFirstImages:(BOOL)fIArg {
    progressBar.progress = per;
}
#pragma mark - progres bar

-(void)showProgressBar {
    progressBar.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^() {
        mapView.frame = CGRectMake(0, 0, mapView.frame.size.width, self.view.frame.size.height - 12);
    }];
}
-(void)hideProgressBar {
    [UIView animateWithDuration:0.2 animations:^() {
        mapView.frame = CGRectMake(0, 0, mapView.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        progressBar.hidden = YES;
    }];
}

#pragma mark - VideoManagerDelegate

-(void)videoManager:(VideoManager*)sender ProgressChanged:(double)progress {
    progressBar.progress = progress;
}
-(void)videoManagerCreationCompleted:(VideoManager*)sender {
    [self.view.window setUserInteractionEnabled:YES];
    [self hideProgressBar];
    
    NSURL* videoURL = [[NSURL alloc] initFileURLWithPath:videoManager.videoPath];
    
    [self openVideoWithURL:videoURL];
}

#pragma mark - open video

- (IBAction)createVideo:(id)sender {
    // UIVIew For create screenshots for video (rotate Pano in the direction of motion
    if (!streetImageView) {
        streetImageView = [[InfiniteImageScrollView alloc] initWithFrame:CGRectMake(0, 0, scrContainer.bounds.size.width, scrContainer.bounds.size.height)];
        [scrContainer insertSubview:streetImageView atIndex:0];
        streetImageView.infdelegate = self;
    }
    [self showProgressBar];
    
    [[BackgroundTaskManager sharedBackgroundTaskManager] beginNewBackgroundTask];
    
    //Start loading pano images
    [panoLoader loadForCoordinatesArray:routeManager.routePoints];
    
    [self.view.window setUserInteractionEnabled:NO];
    
//    [videoManager startCreationVideoForImages:imagesPathArr];
}

-(void)openVideoWithURL:(NSURL*)urlArg {
    if (urlArg) {
        if (!playercontroller) {
            playercontroller = [[MPMoviePlayerViewController alloc]
                                initWithContentURL:urlArg];
            
            playercontroller.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
        }
        
        [self.navigationController pushViewController:playercontroller animated:YES];
    }
}

#pragma mark - map

-(BOOL)isPointInsideinAnnotationViewForGestureRecognizer:(UIGestureRecognizer*)sender {
    BOOL needAddedNewPoint = YES;
    
    for (id<MKAnnotation> annotation in mapView.annotations) {
        MKAnnotationView* annotationView = [mapView viewForAnnotation:annotation];
        CGPoint annotationViewPoint = [sender locationInView:annotationView];
        if (annotationViewPoint.x > 0 && annotationViewPoint.y > 0 && annotationViewPoint.x < annotationView.bounds.size.width && annotationViewPoint.y < annotationView.bounds.size.height) {
            needAddedNewPoint = NO;
            break;
        }
    }
    
    return needAddedNewPoint;
}
-(void)addPointToRouteAtCoordinates:(CLLocationCoordinate2D)coord {
    [routeManager addRoutePointToLocation:coord]; // add point to create route on the map
}
-(void)taptapGestureRecognizer:(UIGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded){
        if (routeManager.isCanEditRouteEnable) {
            if ([self isPointInsideinAnnotationViewForGestureRecognizer:sender]) {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                CGPoint tapPoint = [sender locationInView:mapView];
                CLLocationCoordinate2D newLocation = [mapView convertPoint:tapPoint toCoordinateFromView:mapView];
                [self addPointToRouteAtCoordinates:newLocation];
            }
        }
    }
}


#pragma mark - RouteManagerDelegate

-(void)routeCreated {
    createVideoButton.enabled = YES;
}

#pragma mark - init

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imagesPathArr = [NSMutableArray array];
    
    videoManager = [[VideoManager alloc] init];
    videoManager.delegate = self;
    videoManager.speed = 1.0/10.0;
    
    // Need for multiplyDelegation for use map's event in different parts of the code
    mapViewMultiplyDelegate = [[LWSMapViewMultiplyDelegate alloc] init];
    mapViewMultiplyDelegate.map = mapView;
    [mapViewMultiplyDelegate setMapViewDelegate:self];
    
    routeManager = [[RouteManager alloc] init];
    routeManager.mapMultiplyDelegate = mapViewMultiplyDelegate;
    routeManager.delegate = self;
    
    panoLoader = [[PanoLoader alloc] init];
    panoLoader.delegate = self;
    
    tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(taptapGestureRecognizer:)];
    [tapRec setNumberOfTapsRequired:1];
    [tapRec setNumberOfTouchesRequired:1];
    tapRec.delegate = self;
    [mapView addGestureRecognizer:tapRec];
    
    createVideoButton.enabled = NO;
    
    routeManager.isCanEditRouteEnable = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
