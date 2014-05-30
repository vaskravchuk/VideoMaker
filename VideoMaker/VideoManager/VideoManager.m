//
//  IQProjectVideo
//
//  Created by Iftekhar Mac Pro on 9/26/13.
//  Copyright (c) 2013 Iftekhar. All rights reserved.


#import "VideoManager.h"
#import <AVFoundation/AVFoundation.h>
#import "BackgroundTaskManager.h"

@implementation VideoManager {
    NSOperationQueue* operationQueue;
    
    AVAssetWriter* videoWriter;
    AVAssetWriterInput* writerInput;
    AVAssetWriterInputPixelBufferAdaptor* adaptor;
    CVPixelBufferRef buffer;
    NSUInteger currentIndex;
    
    BOOL isProcessCreating;
    dispatch_queue_t assetWriterQueue;
    int currentIndexForBuff;
    
    NSArray* imagesPathsForVideo;
    
    NSString* videoPath;
}
@synthesize videoPath,isVideoCreating,delegate,isVideoCreationCompleted,isVideoCreationFailed,speed,videoSize;



- (id)init {
    self = [super init];
    if (self) {
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        buffer = NULL;
        currentIndex = 0;
        speed = 1;
        videoPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        videoPath = [videoPath stringByAppendingString:@"/movie.mov"];
        videoSize = CGSizeMake(640, 390);
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)isVideoFailed {
    AVAssetWriterStatus statusW = [videoWriter status];
    return statusW == AVAssetWriterStatusFailed;
}
-(BOOL)isVideoCreationCompleted {
    AVAssetWriterStatus statusW = [videoWriter status];
    return statusW == AVAssetWriterStatusCompleted;
}
-(void)cancelVideoCreation {
    @try {
        if ([videoWriter.inputs containsObject:writerInput]) {
            [writerInput markAsFinished];
        }
    }
    @catch (NSException* ex) {
    }
    writerInput = nil;
    videoWriter = nil;
    isVideoCreating = NO;
    buffer = NULL;
    currentIndex = 0;
    isProcessCreating = NO;
    [operationQueue cancelAllOperations];
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];
}

-(void)prepareToStartCreationVideo {
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath])
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    
    NSError *error = nil;
    videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:videoPath]
                                            fileType:AVFileTypeQuickTimeMovie
                                               error:&error];
    
    NSDictionary *videoSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey,
                                   nil];
    
    writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
}
-(void)startCreationVideo
{
    [[BackgroundTaskManager sharedBackgroundTaskManager] beginNewBackgroundTask];
    isVideoCreating = YES;
    @try {
        currentIndexForBuff = 0;
        if (imagesPathsForVideo.count > 0) {
            [self prepareToStartCreationVideo];
            
            assetWriterQueue = dispatch_queue_create("AssetWriterQueue", DISPATCH_QUEUE_SERIAL);
            [self fillBuffer];
        }
    }
    @catch (NSException* ex) {
        LOG_CMD;
    }
}

-(void)startCreationVideoForImages:(NSArray*)arr {
    if (!self.isVideoCreating && arr && arr.count > 0) {
        imagesPathsForVideo = [NSArray arrayWithArray:arr];
        [self startCreationVideo];
    }
}


-(UIImage*)imageForIndex:(int)index {
    UIImage* res;
    if (index >= 0 && index < imagesPathsForVideo.count) {
        res = [UIImage imageWithContentsOfFile:imagesPathsForVideo[index]];
    }
    return res;
}
-(void)finishVideo {
    [writerInput markAsFinished];
    AVAssetWriterStatus statusW = videoWriter.status;
    if (statusW == AVAssetWriterStatusWriting) {
        [videoWriter finishWritingWithCompletionHandler:^(){
            [self videoCreationFinishingEnd];
        }];
    }
    else {
        [videoWriter finishWritingWithCompletionHandler:^(){}];
        [self cancelVideoCreation];
    }
}
-(void)videoCreationFinishingEnd {
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    [self cancelVideoCreation];
    if ([self.delegate respondsToSelector:@selector(videoManagerCreationCompleted:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate videoManagerCreationCompleted:self];
        });
    }
}
-(void)fillBuffer {
    @try {
        isProcessCreating = YES;
        [writerInput requestMediaDataWhenReadyOnQueue:assetWriterQueue usingBlock:^{
            if (!isProcessCreating) {
                return;
            }
            if (buffer == NULL)
            {
                CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
            }
            UIImage *image = [self imageForIndex:currentIndexForBuff];
            if (!isProcessCreating) {
                return;
            }
            if (image) {
                buffer = [self pixelBufferFromCGImage:image.CGImage];
                int32_t timeScale = ceil(speed*imagesPathsForVideo.count);
                if (speed<1) {
                    timeScale = ceil(1.0/speed);
                }
                CMTime presentTime= CMTimeMakeWithSeconds(speed*currentIndexForBuff, 33);
                if (![adaptor appendPixelBuffer:buffer withPresentationTime:presentTime]) {
                    [self finishVideo];
                    return;
                }
                CVPixelBufferRelease(buffer);
                if (currentIndexForBuff < imagesPathsForVideo.count) {
                }
                else {
                    [self finishVideo];
                }
                if ([self.delegate respondsToSelector:@selector(videoManager:ProgressChanged:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        double percent = (double)currentIndexForBuff/(double)imagesPathsForVideo.count;
                        if (!isnan(percent)) {
                            [self.delegate videoManager:self ProgressChanged:percent];
                        }
                    });
                }
            }
            else {
                if (currentIndexForBuff < imagesPathsForVideo.count) {
                }
                else {
                    [self finishVideo];
                }
                if ([self.delegate respondsToSelector:@selector(videoManager:ProgressChanged:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        double percent = (double)currentIndexForBuff/(double)imagesPathsForVideo.count;
                        if (!isnan(percent)) {
                            [self.delegate videoManager:self ProgressChanged:percent];
                        }
                    });
                }
                return;
            }
            ++currentIndexForBuff;
        }];
    }
    @catch (NSException* ex) {
        LOG_CMD;
    }
}

//Helper functions
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    if (image) {
        NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 nil];
        
        CVPixelBufferRef pxbuffer = NULL;
        CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                            CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                            &pxbuffer);
        
        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                     CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                     kCGImageAlphaNoneSkipFirst);
        
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                               CGImageGetHeight(image)), image);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        
        return pxbuffer;
    }
    else {
        NSLog(@"image is nil");
        return nil;
    }
}

@end
