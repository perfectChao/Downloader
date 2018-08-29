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

typedef NS_ENUM(NSInteger, KSDBGetDataOption) {
    KSDBGetDataOptionAllCacheData = 0,      // 所有缓存数据
    KSDBGetDataOptionAllDownloadingData,    // 所有正在下载的数据
    KSDBGetDataOptionAllDownloadedData,     // 所有下载完成的数据
    KSDBGetDataOptionAllUnDownloadedData,   // 所有未下载完成的数据
    KSDBGetDataOptionAllWaitingData,        // 所有等待下载的数据
    KSDBGetDataOptionModelWithUrl,          // 通过url获取单条数据
    KSDBGetDataOptionWaitingModel,          // 第一条等待的数据
    KSDBGetDataOptionLastDownloadingModel,  // 最后一条正在下载的数据
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
    if (model == nil) return;
    [model save];
}

- (KSDownloadModel *)getModelWithURLString:(NSString *)URLString {
    return [self getModelWithOption:KSDBGetDataOptionModelWithUrl url:URLString];
}

- (KSDownloadModel *)getWaitingModel {
    return [self getModelWithOption:KSDBGetDataOptionWaitingModel url:nil];
}

- (KSDownloadModel *)getLastDownloadingModel {
    return [self getModelWithOption:KSDBGetDataOptionLastDownloadingModel url:nil];
}

- (NSArray<KSDownloadModel *> *)getAllCacheData {
    return [self getDateWithOption:KSDBGetDataOptionAllCacheData];
}

- (NSArray<KSDownloadModel *> *)getAllDownloadingData {
    return [self getDateWithOption:KSDBGetDataOptionAllDownloadingData];
}

- (NSArray<KSDownloadModel *> *)getAllDownloadedData {
    return [self getDateWithOption:KSDBGetDataOptionAllDownloadedData];
}

- (NSArray<KSDownloadModel *> *)getAllUnDownloadedData {
    return [self getDateWithOption:KSDBGetDataOptionAllUnDownloadedData];
}

- (NSArray<KSDownloadModel *> *)getAllWaitingData {
    return [self getDateWithOption:KSDBGetDataOptionAllWaitingData];
}

- (KSDownloadModel *)getModelWithOption:(KSDBGetDataOption)option url:(NSString *)url {
    KSDownloadModel *model = nil;
    switch (option) {
        case KSDBGetDataOptionModelWithUrl: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE URLString = ?" arguments:@[url]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        case KSDBGetDataOptionWaitingModel: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime asc limit 0,1" arguments:@[[NSNumber numberWithInteger:KSDownloadStateWaiting]]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        case KSDBGetDataOptionLastDownloadingModel: {
            NSArray *list = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime desc limit 0,1" arguments:@[[NSNumber numberWithInteger:KSDownloadStateDownloading]]];
            model = list.count ? list.firstObject : nil;
        } break;
            
        default:
            break;
    }
    return model;
}

- (NSArray<KSDownloadModel *> *)getDateWithOption:(KSDBGetDataOption)option {
    NSArray<KSDownloadModel *> *array = nil;
    switch (option) {
        case KSDBGetDataOptionAllCacheData:
            array = [KSDownloadModel objectsWhere:@"WHERE 1 = 1" arguments:nil];
            break;
            
        case KSDBGetDataOptionAllDownloadingData:
            array = [KSDownloadModel objectsWhere:@"WHERE state = ? order by lastStateTime desc" arguments:@[[NSNumber numberWithInteger:KSDownloadStateDownloading]]];
            break;
            
        case KSDBGetDataOptionAllDownloadedData:
            array = [KSDownloadModel objectsWhere:@"WHERE state = ?" arguments:@[[NSNumber numberWithInteger:KSDownloadStateFinish]]];
            break;
            
        case KSDBGetDataOptionAllUnDownloadedData:
            array = [KSDownloadModel objectsWhere:@"WHERE state != ?" arguments:@[[NSNumber numberWithInteger:KSDownloadStateFinish]]];
            break;
            
        case KSDBGetDataOptionAllWaitingData:
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
        
        NSMutableDictionary *dict = @{
                               @"tmpFileSize" : @(model.tmpFileSize),
                               @"totalFileSize" : @(model.totalFileSize),
                               @"progress" : @(model.progress),
                               @"state" : @(model.state),
                               @"lastStateTime" : @([KSDownloaderTool getTimeStampWithDate:[NSDate date]])
                               }.mutableCopy;
        if (!model.resumeData) [dict setObject:model.resumeData forKey:@"resumeData"];
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
