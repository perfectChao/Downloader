//
//  KSDownloadModel.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "KSDownloadModel.h"

@implementation KSDownloadModel

#pragma mark - Getter

- (NSString *)localPath {
    if (!_localPath) {
        NSString *str = [NSString stringWithFormat:@"%@_%@", _vid, @"kaishu"];
        _localPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:str];
    }
    return _localPath;
}

#pragma mark - DB

+ (NSString *)dbName {
    return @"KSDownloadCenter";
}

+ (NSString *)tableName {
    return @"KSDownload";
}

+ (NSString *)primaryKey {
    return @"vid";
}

+ (NSArray *)persistentProperties {
    static NSArray *properties = nil;
    if (!properties) {
        properties = @[
                       @"vid",
                       @"URLString",
                       @"localPath",
                       @"state",
                       @"resumeData",
                       @"totalFileSize",
                       @"tmpFileSize",
                       @"progress",
                       @"lastStateTime",
                       @"fileName"
                       ];
    }
    return properties;
}

@end
