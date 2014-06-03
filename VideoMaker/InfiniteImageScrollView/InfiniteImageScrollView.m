//
//  InfiniteImageScrollView.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 02.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "InfiniteImageScrollView.h"
#import "TIleImageView.h"
#import "ImageCache.h"
#import "PanoPoint.h"
#import <MapKit/MapKit.h>

@interface InfiniteImageScrollView () <UIScrollViewDelegate> {
    NSArray* imagesArr;
    
    BOOL needAutomationRotate;
    PanoPoint* currentPanoPoint;
    double xPanoOffset;
    
    CGPoint contentOffsetWithoutDelay;
}

@property (nonatomic, strong) NSMutableArray *visibleLabels;
@property (nonatomic, strong) UIView *labelContainerView;

@end


@implementation InfiniteImageScrollView

@synthesize infdelegate,needAutomationRotate,imagesCurentIndex,isOnTheScreen,isStartVideo;

-(double)angleBetweenCoord1:(CLLocationCoordinate2D)coordsS Coord2:(CLLocationCoordinate2D)coordsE {
    //    double DEGREE_PER_RADIAN = 57.2957795;
    double RADIAN_PER_DEGREE = M_PI/180.0;
    double dlat = coordsE.latitude - coordsS.latitude;
    double dlng = coordsE.longitude - coordsS.longitude;
    // We multiply dlng with cos(endLat), since the two points are very closeby,
    // so we assume their cos values are approximately equal.
    double angle = atan2(dlng * cos(coordsE.latitude * RADIAN_PER_DEGREE), dlat);
    if (angle >= 2*M_PI) {
        angle -= 2*M_PI;
    } else if (angle < 0) {
        angle += 2*M_PI;
    }
    return angle;
}
-(void)setFrame:(CGRect)frameArg {
    CGSize oldsizes;
    oldsizes.width = (frameArg.size.width - self.frame.size.width)/2.0;
    oldsizes.height = (frameArg.size.height - self.frame.size.height)/2.0;
    [super setFrame:frameArg];
    if (oldsizes.width != 0 || oldsizes.height != 0) {
        [self performSelector:@selector(updateFrameForSizeOffsets:) withObject:[NSValue valueWithCGSize:oldsizes] afterDelay:0.05];
    }
    else {
        [self setNeedsDisplay];
    }
}
-(void)updateFrameForSizeOffsets:(NSValue*)oldSizeArg {
    CGSize oldSize = [oldSizeArg CGSizeValue];
    [self setContentOffset:CGPointMake(contentOffsetWithoutDelay.x-oldSize.width, contentOffsetWithoutDelay.y-oldSize.height)];
    [self updateLayouts];
}
-(void)setIsOnTheScreen:(BOOL)arg {
    isOnTheScreen = arg;
}
-(void)resetImages {
    @try {
        imagesCurentIndex = 0;
        imagesArr = [NSArray array];
        self.contentOffset = CGPointMake(0, (([self contentSize].height/self.zoomScale)*((180-90)*M_PI/180.0)/M_PI)*self.zoomScale - self.frame.size.height/2);
        for (TileImageView* item in self.visibleLabels) {
            @autoreleasepool {
                [item setImagesArr:nil];
            }
        }
    }
    @catch (NSException* ex) {
    }
}
-(void)addedImagesArrForAnimating:(NSArray*)arg {
    imagesArr = [NSArray arrayWithArray:arg];
}
-(void)updateImagesArrForAnimating:(NSArray*)arg {
    @try {
        if (imagesCurentIndex >= arg.count) {
            imagesCurentIndex = 0;
            [self addedImagesArrForAnimating:arg];
        }
        else {
            if (imagesCurentIndex == 0 && [arg count] > [imagesArr count] && [arg count] <= 2) {
                [self setImagesArrForAnimating:arg];
            }
            else {
                [self addedImagesArrForAnimating:arg];
            }
        }
    }
    @catch (NSException* ex) {
    }
}
-(void)setImagesArrForAnimating:(NSArray*)arg {
    @try {
        imagesCurentIndex = 0;
        imagesArr = [NSArray arrayWithArray:arg];
        if ([imagesArr count] > 0) {
            currentPanoPoint = imagesArr[0];
            self.labelContainerView.frame = CGRectMake(0, 0, 4*512*3*self.zoomScale, (2*512-200)*self.zoomScale);
            self.contentSize = CGSizeMake(self.labelContainerView.frame.size.width, self.labelContainerView.frame.size.height);
            [[ImageCache instance] removeCache];
            [self performSelector:@selector(showCurrentScene) withObject:nil afterDelay:0.1];
        }
    }
    @catch (NSException* ex) {
    }
}
-(void)didMoveToWindow:(UIWindow *)newWindow {
    [self setNeedsDisplay];
}

-(void)setContentOffset:(CGPoint)contentOffsetArg {
    if (contentOffsetArg.y < 0) {
        contentOffsetArg.y = 0;
    }
    if (contentOffsetArg.y + self.frame.size.height > self.contentSize.height) {
        contentOffsetArg.y = self.contentSize.height - self.frame.size.height;
    }
    contentOffsetWithoutDelay = contentOffsetArg;
    [super setContentOffset:contentOffsetArg];
}

#pragma mark - interaction
-(void)setIsStartVideo:(BOOL)isStartVideoArg {
    isStartVideo = isStartVideoArg;
    if (isStartVideo) {
    }
    else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.minimumZoomScale = 1;
        } else {
            self.minimumZoomScale = 1.5;
        }
    }
}
-(int)imagesCount {
    return imagesArr.count;
}
-(void)showCurrentScene {
    @try {
        if ([imagesArr count] > 0) {
            currentPanoPoint = imagesArr[imagesCurentIndex];
            if ([self.infdelegate respondsToSelector:@selector(newAnimationPositionsForPanoPoint:)]) {
                [self.infdelegate newAnimationPositionsForPanoPoint:currentPanoPoint];
            }
            [self setZoomScale:self.minimumZoomScale];
            double yGyroOffset = 0;
            double xGyroOffset = 0;
            BOOL rotateToNextPoint = YES;
            CGFloat contentWidth = ([self contentSize].width/self.zoomScale)/3-xPanoOffset;
            if (rotateToNextPoint) {
                double angle = 0;
                if (imagesArr.count > 1) {
                    if (imagesCurentIndex < imagesArr.count-1) {
                        PanoPoint* panoPointNext = imagesArr[imagesCurentIndex+1];
                        angle = [self angleBetweenCoord1:currentPanoPoint.coordinates Coord2:panoPointNext.coordinates];
                    }
                    else if (imagesCurentIndex == imagesArr.count - 1) {
                        PanoPoint* panoPointPrev = imagesArr[imagesCurentIndex-1];
                        angle = [self angleBetweenCoord1:panoPointPrev.coordinates Coord2:currentPanoPoint.coordinates];
                    }
                }
                else {
                    
                }
                angle = -currentPanoPoint.heading*M_PI/180.0+angle + M_PI;
                if (angle >= 2*M_PI) {
                    angle -= 2*M_PI;
                } else if (angle < 0) {
                    angle += 2*M_PI;
                }
                double xOffset = (contentWidth) * angle / (2*M_PI) + yGyroOffset;
                if ([self.visibleLabels count] > 0) {
                    TileImageView* item=self.visibleLabels[0];
                    xOffset += item.frame.origin.x;
                }
                //            if (needAutomationRotate) {
                //                [self setContentOffset:CGPointMake(xOffset - self.frame.size.width/2, self.labelContainerView.frame.size.height - self.frame.size.height - 295+xGyroOffset) animated:YES];
                //            }
                //            else {
                self.contentOffset = CGPointMake((xOffset*self.zoomScale - (self.frame.size.width)/2), (([self contentSize].height/self.zoomScale)*((180-90)*M_PI/180.0)/M_PI + xGyroOffset)*self.zoomScale - self.frame.size.height/2);
                //            }
                [self recenterIfNecessary];
            }
            else {
                double angle = currentPanoPoint.savedHeading;
                if (angle >= 2*M_PI) {
                    angle -= 2*M_PI;
                } else if (angle < 0) {
                    angle += 2*M_PI;
                }
                double xOffset = contentWidth * angle / (2*M_PI) ;
                
                if ([self.visibleLabels count] > 0) {
                    TileImageView* item=self.visibleLabels[0];
                    xOffset += item.frame.origin.x;
                }
                self.contentOffset = CGPointMake(xOffset*self.zoomScale - self.frame.size.width/2 + yGyroOffset*self.zoomScale, (([self contentSize].height/self.zoomScale)*currentPanoPoint.savedTiltHeading/M_PI + xGyroOffset)*self.zoomScale - self.frame.size.height/2);
                [self recenterIfNecessary];
            }
            
            for (TileImageView* item in self.visibleLabels) {
                @autoreleasepool {
                    [item setImagesArr:currentPanoPoint.imageFilePaths];
                }
            }
        }
        needAutomationRotate = NO;
    }
    @catch (NSException* ex) {
    }
}

-(void)toFirstScene {
    if (imagesCurentIndex != 0) {
    }
    imagesCurentIndex = 0;
    [self showCurrentScene];
}
-(void)nextScene {
    if ([imagesArr count] > 1) {
        ++imagesCurentIndex;
        if (imagesCurentIndex >= imagesArr.count) {
            imagesCurentIndex = imagesArr.count - 1;
        }
        else {
            [self showCurrentScene];
        }
    }
}
-(void)goToSceneWithIndex:(int)indexArg {
    imagesCurentIndex = indexArg;
    if (imagesCurentIndex >= imagesArr.count) {
        imagesCurentIndex = imagesArr.count - 1;
    }
    if (imagesCurentIndex < 0) {
        imagesCurentIndex = 0;
    }
    [self showCurrentScene];
}
-(BOOL)isEndScene {
    return imagesCurentIndex >= imagesArr.count-1;
}
-(void)prevScene {
    if ([imagesArr count] > 1) {
        --imagesCurentIndex;
        if (imagesCurentIndex < 0) {
            imagesCurentIndex = 0;
        }
        else {
            [self showCurrentScene];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.needAutomationRotate = YES;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([imagesArr count] > 0) {
        currentPanoPoint = imagesArr[imagesCurentIndex];
        currentPanoPoint.zoom = self.zoomScale;
    }
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.labelContainerView;
}

#pragma mark - initialization

-(void)fillView {
    xPanoOffset = 147;
    self.autoresizesSubviews = NO;
    self.contentSize = CGSizeMake(4*512, self.frame.size.height);
    
    _visibleLabels = [[NSMutableArray alloc] init];
    
    _labelContainerView = [[UIView alloc] init];
    _labelContainerView.autoresizesSubviews = NO;
    _labelContainerView.clipsToBounds = YES;
    [self addSubview:self.labelContainerView];
    
    [self.labelContainerView setUserInteractionEnabled:NO];
    
    // hide horizontal scroll indicator so our recentering trick is not revealed
    [self setShowsHorizontalScrollIndicator:NO];
    
    self.bounces = NO;
    
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.bouncesZoom = NO;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.minimumZoomScale = 1;
        self.maximumZoomScale = 3;
    } else {
        self.minimumZoomScale = 1.5;
        self.maximumZoomScale = 3;
    }
    
    
    UITapGestureRecognizer* tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideo)];
    [tapGR setNumberOfTapsRequired:1];
    [tapGR setNumberOfTouchesRequired:1];
    [self addGestureRecognizer:tapGR];
}
-(void)tapOnVideo {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tapOnVideo" object:nil];
}

-(id)init {
    if (self = [super init]) {
        [self fillView];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self fillView];
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self fillView];
    }
    return self;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Layout

// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary
{
    @try {
        CGPoint currentOffset = contentOffsetWithoutDelay;
        CGFloat contentWidth = [self contentSize].width;
        if (currentOffset.x > 2*contentWidth/3-xPanoOffset*self.zoomScale) {
            currentOffset = CGPointMake(contentWidth/3 + currentOffset.x - (2*contentWidth/3-xPanoOffset*self.zoomScale), currentOffset.y);
            self.contentOffset = currentOffset;
        }
        else if (currentOffset.x < contentWidth/3) {
            currentOffset = CGPointMake(2*contentWidth/3 + currentOffset.x - contentWidth/3-xPanoOffset*self.zoomScale, currentOffset.y);
            self.contentOffset = currentOffset;
        }
        TileImageView* offsetView = nil;
        CGPoint offsetViewPoint;
        for (TileImageView* item in self.visibleLabels) {
            CGPoint itemPoint = [self convertPoint:currentOffset toView:item];
            CGPoint itemPoint2 = [item convertPoint:item.frame.origin toView:self];
            
            if (itemPoint.x >= 0 && itemPoint.x <= item.frame.size.width-xPanoOffset) {
                offsetView = item;
                offsetViewPoint = itemPoint2;
                break;
            }
        }
    }
    @catch (NSException* ex) {
    }
}

-(void)updateLayouts {
    @try {
        if ([imagesArr count] > 0) {
            
            [self recenterIfNecessary];
            
            // tile content in visible bounds
            
            CGRect visibleBounds = [self convertRect:[self bounds] toView:self.labelContainerView];
            CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
            CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
            
            BOOL needRedraw = [self.visibleLabels count] == 0;
            [self tileLabelsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
            if (needRedraw) {
                [self performSelector:@selector(setImagesArrForAnimating:) withObject:imagesArr afterDelay:0.01];
            }
            
            
            for (TileImageView* item in self.visibleLabels) {
                @autoreleasepool {
                    [item updateImages];
                }
            }
        }
    }
    @catch (NSException* ex) {
    }
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateLayouts];
}

#pragma mark - Label Tiling

- (UIView *)insertLabel
{
    TileImageView* resView = [[TileImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    if (imagesArr.count > 0) {
        PanoPoint* panoPoint = imagesArr[imagesCurentIndex];
        resView = [[TileImageView alloc] initWithFrame:CGRectMake(0, 0, 4*512, 2*512-200)];
        
        [resView setImagesArr:panoPoint.imageFilePaths];
    }
    [self.labelContainerView addSubview:resView];
    
    return resView;
}

- (CGFloat)placeNewLabelOnRight:(CGFloat)rightEdge
{
    UIView *label = [self insertLabel];
    [self.visibleLabels addObject:label]; // add rightmost label at the end of the array
    
    CGRect frame = [label frame];
    frame.origin.x = rightEdge;
    frame.origin.y = [self.labelContainerView bounds].size.height - frame.size.height;
    [label setFrame:frame];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewLabelOnLeft:(CGFloat)leftEdge
{
    UIView *label = [self insertLabel];
    [self.visibleLabels insertObject:label atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [label frame];
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = [self.labelContainerView bounds].size.height - frame.size.height;
    [label setFrame:frame];
    
    return CGRectGetMinX(frame);
}

- (void)tileLabelsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([self.visibleLabels count] == 0)
    {
        [self placeNewLabelOnRight:minimumVisibleX];
    }
    
    // add labels that are missing on right side
    UILabel *lastLabel = [self.visibleLabels lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame])-xPanoOffset;
    while (rightEdge < maximumVisibleX)
    {
        rightEdge = [self placeNewLabelOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UILabel *firstLabel = self.visibleLabels[0];
    CGFloat leftEdge = CGRectGetMinX([firstLabel frame])+xPanoOffset;
    while (leftEdge > minimumVisibleX)
    {
        leftEdge = [self placeNewLabelOnLeft:leftEdge];
    }
}

@end
