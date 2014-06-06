//
//  InfiniteImageScrollView.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 02.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PanoPoint.h"

@protocol InfiniteImageScrollViewDelegate <NSObject>

@optional
-(void)newAnimationPositionsForPanoPoint:(PanoPoint*)panoPointArg;

@end

@interface InfiniteImageScrollView : UIScrollView
@property(nonatomic,weak)id<InfiniteImageScrollViewDelegate> infdelegate;
@property(nonatomic,assign)BOOL needAutomationRotate;
@property(nonatomic,assign)int imagesCurentIndex;
@property(nonatomic,readonly)int imagesCount;
@property (nonatomic,assign)BOOL isOnTheScreen;
@property (nonatomic,assign)BOOL isStartVideo;

-(void)setImagesArrForAnimating:(NSArray*)arg;
-(void)updateImagesArrForAnimating:(NSArray*)arg;
-(void)updateFrameForSizeOffsets:(NSValue*)oldSizeArg;
-(void)resetImages;

-(void)nextScene;
-(void)prevScene;
-(void)goToSceneWithIndex:(int)indexArg;
-(void)toFirstScene;
-(BOOL)isEndScene;
-(void)showCurrentScene;

@end
