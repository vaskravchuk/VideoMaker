//
//  ImageCache.m
//  GoogleStreetViewVideoTest
//
//  Created by Василий Кравчук on 28.11.13.
//  Copyright (c) 2013 lws. All rights reserved.
//

#import "ImageCache.h"

@interface ImageCache () {
    NSMutableDictionary* cache;
}


@end
@implementation ImageCache


+ (ImageCache*)instance{
	static ImageCache *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[ImageCache alloc] init];
		}
	}
	
	return instance;
	
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [self removeCache];
}

-(id)init {
    if (self = [super init]) {
        cache = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}


-(UIImage*)imageFromFile:(NSString*)str {
    UIImage* im = [cache objectForKey:str];
    @try {
        if (!im) {
            im = [UIImage imageWithContentsOfFile:str];
            if (im) {
                [cache setObject:im forKey:str];
                if ([[cache allKeys] count] > 100) {
                    [cache removeObjectForKey:[cache allKeys][0]];
                }
            }
        }
        else {
        }
    }
    @catch (NSException* ex) {
    }
    return im;
}

-(void)removeCache {
    [cache removeAllObjects];
}

@end
