//
//  PanoLoader.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 01.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanoPoint.h"

@protocol PanoLoaderDelegate <NSObject>

-(void)allImagesLoaded:(NSArray*)resArrArg;
-(void)loaderProcess:(double)per withPanoPoint:(PanoPoint*)arg isFirstImages:(BOOL)fIArg;// SceneSize:(double)sizeP ForTime:(double)per;

@end

@interface PanoLoader : NSObject
@property(nonatomic,strong)id<PanoLoaderDelegate> delegate;
@property(nonatomic,strong)NSMutableArray* loadedImages;
@property(nonatomic,strong)NSMutableArray* coordArr;
@property(nonatomic,assign)int currentCoordArrIndex;
@property(nonatomic,assign)double averageDownloadSpeed;
@property(nonatomic,assign)double averagePackageSize;
@property(nonatomic,assign)double allPackageSize;
@property(nonatomic,readonly)BOOL isStopedLoadingPano;
-(void)loadForCoordinatesArray:(NSArray*)arg;
-(void)stopLoadingImages;
@end
