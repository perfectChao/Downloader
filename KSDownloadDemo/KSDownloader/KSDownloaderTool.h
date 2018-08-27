//
//  KSDownloaderTool.h
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/27.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

static inline void ks_dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface KSDownloaderTool : NSObject

/**
 通过NSDate获取时间戳

 @param date date
 @return 时间戳
 */
+ (NSInteger)getTimeStampWithDate:(NSDate *)date;

/**
 将byteCount格式化

 @param byteCount byteCount
 @return 格式化后的字符串
 */
+ (NSString *)stringFromByteCount:(long long)byteCount;

@end
