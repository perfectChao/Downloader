//
//  KSDownloadCache.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "KSDownloadCache.h"
#import "KSDownloadModel.h"
#import "KSDownloaderTool.h"
#import "KSDownloaderTool.h"

NSString *const KSDownloadModelStateChangeNotification = @"KSDownloadModelStateChangeNotification";

typedef NS_ENUM(NSInteger, HWDBGetDateOption) {
    KSDBGetDateOptionAllCacheData = 0,      // 所有缓存数据
    KSDBGetDateOptionAllDownloadingData,    // 所有正在下载的数据
    KSDBGetDateOptionAllDownloadedData,     // 所有下载完成的数据
    KSDBGetDateOptionAllUnDownloadedData,   // 所有未下载完成的数据
    KSDBGetDateOptionAllWaitingData,        // 所有等待下载的数据
    KSDBGetDateOptionModelWithUrl,          // 通过url获取单条数据
    KSDBGetDateOptionWaitingModel,          // 第一条等待的数据
    KSDBGetDateOptionLastDownloadingModel,  // 最后一条正在下载的数据
};

@implementation KSDownloadCache

+(instancetype)sharedCache {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Action

- (void)insertModel:(KSDownloadModel *)model {
    [model save];
}

- (KSDownloadModel *)getModelWithURLString:(NSString *)URLString {
    return [self getModelWithOption:KSDBGetDateOptionModelWithUrl url:URLString];
}

- (KSDownloadModel *)getWaitingModel {
    return [self getModelWithOption:KSDBGetDateOptionWaitingModel url:nil];
}

- (KSDownloadModel *)getLastDownloadingModel {
    return [self getModelWithOption:KSDBGetDateOptionLastDownloadingModel url:nil];
}

- (NSArray<KSDownloadModel *> *)getAllCacheData {
    return [self getDateWithOption:KSDBGetDateOptionAllCacheData];
}

- (NSArray<KSDownloadModel *> *)getAllDownloadingData {
    return [self getDateWithOption:KSDBGetDateOptionAllDownloadingData];
}

- (NSArray<KSDownloadModel *> *)getAllDownloadedData {
    return [self getDateWithOption:KSDBGetDateOptionAllDownloadedData];
}

- (NSArray<KSDownloadModel *> *)getAllUnDownloadedData {
    return [self getDateWithOption:KSDBGetDateOptionAllUnDownloadedData];
}

- (NSArray<KSDownloadModel *> *)getAllWaitingData {
    return [self getDateWithOption:KSDBGetDateOptionAllWaitingData];
}

- (KSDownloadModel *)getModelWithOption:(HWDBGetDateOption)option url:(NSString *)url {
    KSDownloadModel *model = nil;
    switch (option) {
        case KSDBGetDateOptionModelWithUrl: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE URLString = ?" arguments:@[url]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        case KSDBGetDateOptionWaitingModel: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime asc limit 0,1" arguments:@[[NSNumber numberWithInteger:KSDownloadStateWaiting]]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        case KSDBGetDateOptionLastDownloadingModel: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime desc limit 0,1" arguments:@[[NSNumber numberWithInteger:KSDownloadStateDownloading]]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        default:
            break;
    }
    return model;
}

- (NSArray<KSDownloadModel *> *)getDateWithOption:(HWDBGetDateOption)option {
    NSArray<KSDownloadModel *> *array = nil;
    switch (option) {
        case KSDBGetDateOptionAllCacheData:
            array = [KSDownloadModel objectsWhere:@"WHERE 1 = 1" arguments:nil];
            break;
            
        case KSDBGetDateOptionAllDownloadingData:
            array = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime desc" arguments:@[[NSNumber numberWithInteger:KSDownloadStateDownloading]]];
            break;
            
        case KSDBGetDateOptionAllDownloadedData:
            array = [KSDownloadModel objectsWhere:@"WHERE state = ?" arguments:@[[NSNumber numberWithInteger:KSDownloadStateFinish]]];
            break;
            
        case KSDBGetDateOptionAllUnDownloadedData:
            array = [KSDownloadModel objectsWhere:@"WHERE state != ?" arguments:@[[NSNumber numberWithInteger:KSDownloadStateFinish]]];
            break;
            
        case KSDBGetDateOptionAllWaitingData:
            array = [KSDownloadModel objectsWhere:@"WHERE state = ?" arguments:@[[NSNumber numberWithInteger:KSDownloadStateWaiting]]];
            break;
            
        default:
            break;
    }
    return array;
}

- (void)updateWithModel:(KSDownloadModel *)model option:(KSCacheUpdateOption)option {
    if (option & KSCacheUpdateOptionState) {
        [self postStateChangeNotificationWithModel:model];
        [KSDownloadModel updateObjectsSet:@{@"state" : [NSNumber numberWithInteger:model.state]} Where:@"WHERE URLString = ?" arguments:@[model.URLString]];
    }
    
    if (option & KSCacheUpdateOptionLastStateTime) {
        [KSDownloadModel updateObjectsSet:@{@"lastStateTime" : @([KSDownloaderTool getTimeStampWithDate:[NSDate date]])} Where:@"WHERE URLString = ?" arguments:@[model.URLString]];
    }
    
    if (option & KSCacheUpdateOptionResumeData && model.resumeData != nil) {
        [KSDownloadModel updateObjectsSet:@{@"resumeData" : model.resumeData} Where:@"WHERE URLString = ?" arguments:@[model.URLString]];
    }
    
    if (option & KSCacheUpdateOptionProgressData) {
        NSDictionary *dict = @{
                               @"tmpFileSize" : @(model.tmpFileSize),
                               @"totalFileSize" : @(model.totalFileSize),
                               @"progress" : @(model.progress),
                               };
        [KSDownloadModel updateObjectsSet:dict Where:@"WHERE URLString = ?" arguments:@[model.URLString]];
    }
    
    if (option & KSCacheUpdateOptionAllParam) {
        [self postStateChangeNotificationWithModel:model];
        NSDictionary *dict = @{
                               @"resumeData" : model.resumeData,
                               @"tmpFileSize" : @(model.tmpFileSize),
                               @"totalFileSize" : @(model.totalFileSize),
                               @"progress" : @(model.progress),
                               @"state" : @(model.state),
                               @"lastStateTime" : @([KSDownloaderTool getTimeStampWithDate:[NSDate date]])
                               };
        [KSDownloadModel updateObjectsSet:dict Where:@"WHERE URLString = ?" arguments:@[model.URLString]];
    }
}

- (void)postStateChangeNotificationWithModel:(KSDownloadModel *)model {
    ks_dispatch_async_on_main_queue(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KSDownloadModelStateChangeNotification object:model];
    });
}

- (void)deleteModelWithURLString:(NSString *)URLString {
    [KSDownloadModel deleteObjectsWhere:@"WHERE URLString = ?" arguments:@[URLString]];
}

@end
