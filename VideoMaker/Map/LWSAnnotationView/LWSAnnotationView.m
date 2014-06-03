//
//  LWSAnnotationView.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 03.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "LWSAnnotationView.h"
#import "LWSAnnotation.h"
#import <QuartzCore/QuartzCore.h> // For CAAnimation

@interface LWSAnnotationView () {
}
@property (nonatomic, assign) BOOL isMoving;
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) CGPoint originalCenter;

@property (nonatomic, retain) UIImageView *	pinShadow;
@property (nonatomic, retain) UIImageView *	pinSelected;
@property (nonatomic, retain) NSTimer * pinTimer;
@property (nonatomic, assign) MKMapView *mapView;

- (CAAnimation *)pinBounceAnimation_;
- (CAAnimation *)pinFloatingAnimation_;
- (CAAnimation *)pinLiftAnimation_;
- (CAAnimation *)liftForDraggingAnimation_; // Used in touchesBegan:
- (CAAnimation *)liftAndDropAnimation_;		// Used in touchesEnded: when touchesMoved: previous triggered
- (id)initWithAnnotation_:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier mapView:(MKMapView *)mapView;
- (void)shadowLiftWillStart_:(NSString *)animationID context:(void *)context;
- (void)shadowDropDidStop_:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)resetPinPosition_:(NSTimer *)timer;
@end

@implementation LWSAnnotationView
@synthesize pinDown1Image,pinDown2Image,pinDown3Image,pinFloatingImage,pinImage,state;

@synthesize mapView = mapView_;
@synthesize isMoving = isMoving_;
@synthesize startLocation = startLocation_;
@synthesize originalCenter = originalCenter_;
@synthesize pinShadow = pinShadow_;
@synthesize pinTimer = pinTimer_;

-(void)setPinDown1Image:(UIImage *)pinDown1ImageArg {
    pinDown1Image = pinDown1ImageArg;
}
-(void)setPinDown2Image:(UIImage *)pinDown1ImageArg {
    pinDown2Image = pinDown1ImageArg;
}
-(void)setPinDown3Image:(UIImage *)pinDown1ImageArg {
    pinDown3Image = pinDown1ImageArg;
}
-(void)setPinFloatingImage:(UIImage *)pinDown1ImageArg {
    pinFloatingImage = pinDown1ImageArg;
}
-(void)setPinImage:(UIImage *)pinDown1ImageArg {
    pinImage = pinDown1ImageArg;
    self.image = pinImage;
    self.frame = CGRectMake(0, 0, 26, 26);
    self.pinSelected.center = CGPointMake(self.frame.size.width/2 -4, self.frame.size.height/2);
    self.centerOffset = CGPointMake(11, -12);
    LWSAnnotation* theAnnotation = (LWSAnnotation *)self.annotation;
    
    [theAnnotation setCoordinate:theAnnotation.coordinate];
}

// Thanks to Bret Cheng (@bretcheng)'s suggestion on avoiding memory leaks in -initWithAnnotation:reuseIdentifier: when returning MKPinAnnotationView instead
+ (id)annotationViewWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier mapView:(MKMapView *)mapView {
	
	return [[self alloc] initWithAnnotation_:annotation reuseIdentifier:reuseIdentifier mapView:mapView];
}

- (id)initWithAnnotation_:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier mapView:(MKMapView *)mapView {
		
	if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])) {
        state = -1;
		self.centerOffset = CGPointMake(8, -17);
		self.calloutOffset = CGPointMake(-8, 0);
		self.canShowCallout = YES;
		
		self.pinShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flag_shadow.png"]];
		self.pinShadow.frame = CGRectMake(0, 0, 32, 39);
		self.pinShadow.hidden = YES;
		[self addSubview:self.pinShadow];
		self.pinSelected = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flag_select.png"]];
		self.pinSelected.frame = CGRectMake(0, 0, 50, 50);
		self.pinSelected.hidden = YES;
		[self addSubview:self.pinSelected];
		
		self.mapView = mapView;
	}
	
	return self;
}

// NOTE: iOS 4 MapKit won't use the source code below, we return a draggable MKPinAnnotationView instance instead.

#pragma mark -
#pragma mark Core Animation class methods
-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
		self.pinSelected.hidden = NO;
    }
    else {
		self.pinSelected.hidden = YES;
    }
}
- (CAAnimation *)pinBounceAnimation_ {
	
	CAKeyframeAnimation *pinBounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	
	NSMutableArray *values = [NSMutableArray array];
	[values addObject:(id)self.pinDown1Image.CGImage];
	[values addObject:(id)self.pinDown2Image.CGImage];
	[values addObject:(id)self.pinDown3Image.CGImage];
	
	[pinBounceAnimation setValues:values];
	pinBounceAnimation.duration = 0.15;
	
	return pinBounceAnimation;
}

- (CAAnimation *)pinFloatingAnimation_ {
	
	CAKeyframeAnimation *pinFloatingAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	
	[pinFloatingAnimation setValues:[NSArray arrayWithObject:(id)self.pinFloatingImage.CGImage]];
	pinFloatingAnimation.duration = 0.2;
	
	return pinFloatingAnimation;
}

- (CAAnimation *)pinLiftAnimation_ {
	
	CABasicAnimation *liftAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	
	liftAnimation.byValue = [NSValue valueWithCGPoint:CGPointMake(0.0, -40.0)];
	liftAnimation.duration = 0.2;
	
	return liftAnimation;
}

- (CAAnimation *)liftForDraggingAnimation_ {
	
	CAAnimation *pinBounceAnimation = [self pinBounceAnimation_];
	CAAnimation *pinFloatingAnimation = [self pinFloatingAnimation_];
	pinFloatingAnimation.beginTime = pinBounceAnimation.duration;
	CAAnimation *pinLiftAnimation = [self pinLiftAnimation_];
	pinLiftAnimation.beginTime = pinBounceAnimation.duration;
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:pinBounceAnimation, pinFloatingAnimation, pinLiftAnimation, nil];
	group.duration = pinBounceAnimation.duration + pinFloatingAnimation.duration;
	group.fillMode = kCAFillModeForwards;
	group.removedOnCompletion = NO;
	
	return group;
}

- (CAAnimation *)liftAndDropAnimation_ {
	
	CAAnimation *pinLiftAndDropAnimation = [self pinLiftAnimation_];
	CAAnimation *pinFloatingAnimation = [self pinFloatingAnimation_];
	CAAnimation *pinBounceAnimation = [self pinBounceAnimation_];
	pinBounceAnimation.beginTime = pinFloatingAnimation.duration;
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:pinLiftAndDropAnimation, pinFloatingAnimation, pinBounceAnimation, nil];
	group.duration = pinFloatingAnimation.duration + pinBounceAnimation.duration;	
	
	return group;	
}

#pragma mark -
#pragma mark UIView animation delegates

- (void)shadowLiftWillStart_:(NSString *)animationID context:(void *)context {
	self.pinShadow.hidden = NO;
}

- (void)shadowDropDidStop_:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	self.pinShadow.hidden = YES;
    self.dragState = MKAnnotationViewDragStateNone;
}

#pragma mark NSTimer fire method

- (void)resetPinPosition_:(NSTimer *)timer {
    
    [self.pinTimer invalidate];
    self.pinTimer = nil;
    
    [self.layer addAnimation:[self liftAndDropAnimation_] forKey:@"DDPinAnimation"];
    
    // TODO: animation out-of-sync with self.layer
    [UIView beginAnimations:@"DDShadowLiftDropAnimation" context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(shadowDropDidStop_:finished:context:)];
    [UIView setAnimationDuration:0.2];
    self.pinShadow.center = CGPointMake(90, -30);
    self.pinShadow.center = CGPointMake(16.0, 19.5);
    self.pinShadow.alpha = 0;
    [UIView commitAnimations];		
    
    // Update the map coordinate to reflect the new position.
    CGPoint newCenter;
    newCenter.x = self.center.x - self.centerOffset.x;
    newCenter.y = self.center.y - self.centerOffset.y - self.image.size.height + 4.;
    
    LWSAnnotation *theAnnotation = (LWSAnnotation *)self.annotation;
    CLLocationCoordinate2D newCoordinate = [self.mapView convertPoint:newCenter toCoordinateFromView:self.superview];
    [theAnnotation setCoordinate:newCoordinate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DDAnnotationCoordinateDidChangeNotification" object:theAnnotation];
    
    // Clean up the state information.
    self.startLocation = CGPointZero;
    self.originalCenter = CGPointZero;
    self.isMoving = NO;
}

#pragma mark -
#pragma mark Handling events

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView* res = [super hitTest:point withEvent:event];
    if (!res) {
        if (point.x > -11 && point.y > -11 && point.x < self.frame.size.width + 11 && point.y < self.frame.size.height + 11) {
            res = self;
        }
    }
    return res;
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.isMoving = YES;
}
-(void)setDragState:(MKAnnotationViewDragState)dragState animated:(BOOL)animated {
    if (dragState == MKAnnotationViewDragStateEnding || dragState == MKAnnotationViewDragStateCanceling) {
        [[self superview] bringSubviewToFront:self];
		if (self.isMoving) {
            self.isMoving = NO;
			[self.pinTimer invalidate];
			self.pinTimer = nil;
			
			// Update the map coordinate to reflect the new position.
			CGPoint newCenter;
			newCenter.x = self.center.x - self.centerOffset.x;
			newCenter.y = self.center.y - self.centerOffset.y - 40;
            //			newCenter.y = self.center.y - 30;
			
			LWSAnnotation* theAnnotation = (LWSAnnotation *)self.annotation;
			CLLocationCoordinate2D newCoordinate = [self.mapView convertPoint:newCenter toCoordinateFromView:self.superview];
			
			[theAnnotation setCoordinate:newCoordinate];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DDAnnotationCoordinateDidChangeNotification" object:theAnnotation];
			
			[self.layer addAnimation:[self liftAndDropAnimation_] forKey:@"DDPinAnimation"];
			
			// TODO: animation out-of-sync with self.layer
			[UIView beginAnimations:@"DDShadowLiftDropAnimation" context:NULL];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(shadowDropDidStop_:finished:context:)];
			[UIView setAnimationDuration:0.2];
			self.pinShadow.center = CGPointMake(15.0, 10);
//			self.pinShadow.alpha = 0;
			[UIView commitAnimations];
			
			// Clean up the state information.
			self.startLocation = CGPointZero;
			self.originalCenter = CGPointZero;
			self.isMoving = NO;
            
            [self.mapView.delegate mapView:self.mapView annotationView:self didChangeDragState:MKAnnotationViewDragStateEnding fromOldState:MKAnnotationViewDragStateEnding];
		} else {
			
			// TODO: Currently no drop down effect but pin bounce only
			[self.layer addAnimation:[self pinBounceAnimation_] forKey:@"DDPinAnimation"];
			
			// TODO: animation out-of-sync with self.layer
			[UIView beginAnimations:@"DDShadowDropAnimation" context:NULL];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(shadowDropDidStop_:finished:context:)];
			[UIView setAnimationDuration:0.2];
			self.pinShadow.center = CGPointMake(15, 10);
//			self.pinShadow.alpha = 0;
			[UIView commitAnimations];
		}
    }
    else if (dragState == MKAnnotationViewDragStateStarting) {
        
        if (self.mapView) {
            [self.layer removeAllAnimations];
            
            [self.layer addAnimation:[self liftForDraggingAnimation_] forKey:@"DDPinAnimation"];
            
            [UIView beginAnimations:@"DDShadowLiftAnimation" context:NULL];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationWillStartSelector:@selector(shadowLiftWillStart_:context:)];
            [UIView setAnimationDuration:0.2];
            self.pinShadow.center = CGPointMake(35, -15);
            self.pinShadow.alpha = 0.6;
            [UIView commitAnimations];
            self.dragState = MKAnnotationViewDragStateDragging;
        }
    }
//    else if (dragState == MKAnnotationViewDragStateStarting) {
//    [super setDragState:dragState animated:animated];
}

@end
