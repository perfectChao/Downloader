//
//  KSDownloader.h
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KSDownloadModel;

/// 进度通知
extern NSString *const KSDownloadProgressNotification;
/// 网络变化通知
extern NSString *const KSNetworkingReachabilityDidChangeNotification;

/**
 文件下载类, 单例类
 
 [KSDownloader sharedDownloader];
 */
@interface KSDownloader : NSObject

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================

/**
 单例方法, 返回全局下载实例
 
 @return 全局下载实例
 */
+ (nonnull instancetype)sharedDownloader;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

#pragma mark - Download Action
///=============================================================================
/// @name Download Action
///=============================================================================

/**
 开始下载
 暂停后,继续下载
 */
- (void)startDownloadTask:(nullable KSDownloadModel *)model;

/**
 批量开启下载任务
 正在下载中, 已经下载完成的不会重新开启下载
 */
- (void)startDownloadTasks:(nullable NSArray <KSDownloadModel *> *)list;

/**
 暂停所有下载
 */
- (void)suspendAllDownloadTask;

/**
 暂停下载
 */
- (void)suspendDownloadTask:(nullable KSDownloadModel *)model;

/**
 删除下载及本地缓存
 */
- (void)deleteTaskAndCache:(nullable KSDownloadModel *)model;

/**
 下载时, 杀死进程, 更新所有正在下载的任务为等待
 
 注: 使用GYModelObject库时, 修改状态为waiting, 再次启动时仍为downloading, 使用此库需要注意
 */
- (void)updateDownloadingTaskState;

/**
 重启后, 开启等待下载任务
 */
- (void)openDownloadTask;

@end
