//
//  KSDownloaderTool.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/27.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "KSDownloaderTool.h"

@implementation KSDownloaderTool

+ (NSInteger)getTimeStampWithDate:(NSDate *)date {
    return [[NSNumber numberWithDouble:[date timeIntervalSince1970] * 1000 * 1000] integerValue];
}

+ (NSString *)stringFromByteCount:(long long)byteCount {
    return [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
}

@end
