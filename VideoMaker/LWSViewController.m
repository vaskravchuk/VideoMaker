//
//  LWSViewController.m
//  VideoMaker
//
//  Created by Василий Кравчук on 28.05.14.
//  Copyright (c) 2014 lifewaresolutions. All rights reserved.
//

#import "LWSViewController.h"
#import "LWSImageCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoManager.h"

#define CELL_ID @"LWSImageCell ID"

@interface LWSViewController () <UICollectionViewDelegate, UICollectionViewDataSource, VideoManagerDelegate> {
    __weak IBOutlet UICollectionView *collectionView;
    __weak IBOutlet UIProgressView *progressBar;
    NSMutableArray* imagesPathArr;
    MPMoviePlayerViewController *playercontroller;
    VideoManager* videoManager;
}
@end

@implementation LWSViewController

#pragma mark - progres bar

-(void)showProgressBar {
    progressBar.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^() {
        collectionView.frame = CGRectMake(0, 0, collectionView.frame.size.width, self.view.frame.size.height - 12);
    }];
}
-(void)hideProgressBar {
    [UIView animateWithDuration:0.2 animations:^() {
        collectionView.frame = CGRectMake(0, 0, collectionView.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        progressBar.hidden = YES;
    }];
}

#pragma mark - VideoManagerDelegate

-(void)videoManager:(VideoManager*)sender ProgressChanged:(double)progress {
    progressBar.progress = progress;
}
-(void)videoManagerCreationCompleted:(VideoManager*)sender {
    [self hideProgressBar];
    
    NSURL* videoURL = [[NSURL alloc] initFileURLWithPath:videoManager.videoPath];
    NSLog(@"%@",videoURL);
    [self openVideoWithURL:videoURL];
}

#pragma mark - open video

- (IBAction)createVideo:(id)sender {
    [self showProgressBar];
    
    [videoManager startCreationVideoForImages:imagesPathArr];
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imagesPathArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionViewArg cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LWSImageCell* cell = (LWSImageCell*)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_ID forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithContentsOfFile:imagesPathArr[[indexPath row]]];
    
    return cell;
}

#pragma mark - init

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imagesPathArr = [NSMutableArray array];
    for (int i = 0; i < 280; ++i) {
        [imagesPathArr addObject:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"scrForVideo%d.png",i] ofType:nil]];
    }
    
    [collectionView registerClass:[LWSImageCell class] forCellWithReuseIdentifier:CELL_ID];
    videoManager = [[VideoManager alloc] init];
    videoManager.delegate = self;
    videoManager.speed = 1.0/10.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
