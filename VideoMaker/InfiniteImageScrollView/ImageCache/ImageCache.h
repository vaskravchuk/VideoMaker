//
//  ImageCache.h
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 28.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject

+(ImageCache*)instance;
-(UIImage*)imageFromFile:(NSString*)str;
-(void)removeCache;

@end
