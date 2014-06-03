//
//  LWSDirectionService.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 01.10.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LWSDirectionService;
@protocol LWSDirectionServiceDelegate <NSObject>

-(void)directionReceived:(LWSDirectionService*)sender Data:(NSArray*)paths userInfo:(id)userinfoArg;
-(void)directionReceivedFailed:(LWSDirectionService*)sender Data:(NSArray*)paths userInfo:(id)userinfoArg;

@end

@interface LWSDirectionService : NSObject

@property (nonatomic,weak) id<LWSDirectionServiceDelegate> delegate;

- (void)loadDirectionsForLocationsStrings:(NSArray *)locationsStrings userInfo:(id)userinfoArg;
- (void)stopLoadingForUserInfo:(id)userinfoArg;
- (void)stopLoading;
@end
