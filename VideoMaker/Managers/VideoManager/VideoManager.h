//
//  IQProjectVideo
//
//  Created by Iftekhar Mac Pro on 9/26/13.
//  Copyright (c) 2013 Iftekhar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoManager;

@protocol VideoManagerDelegate <NSObject>

@optional
-(void)videoManager:(VideoManager*)sender ProgressChanged:(double)progress;
-(void)videoManagerCreationCompleted:(VideoManager*)sender;

@end

@interface VideoManager : NSObject
@property(nonatomic,weak)id<VideoManagerDelegate> delegate;

@property (nonatomic,strong)NSString* videoPath;
@property(nonatomic,readonly)BOOL isVideoCreating;
@property(nonatomic,readonly)BOOL isVideoCreationFailed;
@property(nonatomic,readonly)BOOL isVideoCreationCompleted;

@property(nonatomic,assign)double speed;
@property(nonatomic,assign)CGSize videoSize;

-(void)startCreationVideoForImages:(NSArray*)arr;
-(void)cancelVideoCreation;

@end
