//
//  KSDownloadCache.h
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KSDownloadModel;

/// 状态变更通知
extern NSString *const KSDownloadModelStateChangeNotification;

/** 缓存更新策略*/
typedef NS_OPTIONS(NSUInteger, KSCacheUpdateOption) {
    KSCacheUpdateOptionState         = 1 << 0,  ///< 更新状态
    KSCacheUpdateOptionLastStateTime = 1 << 1,  ///< 更新状态最后改变的时间
    KSCacheUpdateOptionResumeData    = 1 << 2,  ///< 更新下载的数据
    KSCacheUpdateOptionProgressData  = 1 << 3,  ///< 更新进度数据（包含tmpFileSize、totalFileSize、progress）
    KSCacheUpdateOptionAllParam      = 1 << 4   ///< 更新全部数据
};

/**
 外部不要直接使用, 下载器缓存类
 */
@interface KSDownloadCache : NSObject

/// 单例
+ (instancetype)sharedCache;

/**
 插入数据

 @param model 数据
 */
- (void)insertModel:(KSDownloadModel *)model;

/**
 根据地址查找数据
 */
- (KSDownloadModel *)getModelWithURLString:(NSString *)URLString;

/**
 获取第一条等待的数据
 */
- (KSDownloadModel *)getWaitingModel;

/**
 获取最后一条正在下载的数据
 */
- (KSDownloadModel *)getLastDownloadingModel;

/**
 获取所有数据
 */
- (NSArray<KSDownloadModel *> *)getAllCacheData;

/**
 根据lastStateTime倒叙获取所有正在下载的数据
 */
- (NSArray<KSDownloadModel *> *)getAllDownloadingData;

/**
 获取所有下载完成的数据
 */
- (NSArray<KSDownloadModel *> *)getAllDownloadedData;

/**
 获取所有未下载完成的数据
 */
- (NSArray<KSDownloadModel *> *)getAllUnDownloadedData;

/**
 获取所有等待下载的数据
 */
- (NSArray<KSDownloadModel *> *)getAllWaitingData;

/**
 更新数据
 */
- (void)updateWithModel:(KSDownloadModel *)model option:(KSCacheUpdateOption)option;

/**
 删除数据
 */
- (void)deleteModelWithURLString:(NSString *)URLString;

@end
