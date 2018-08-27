//
//  KSDownloadModel.h
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GYModelObject.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, KSDownloadState) {
    KSDownloadStateDefault = 0,  ///< 默认
    KSDownloadStateDownloading,  ///< 正在下载
    KSDownloadStateWaiting,      ///< 等待
    KSDownloadStatePaused,       ///< 暂停
    KSDownloadStateFinish,       ///< 完成
    KSDownloadStateError,        ///< 错误
};

@interface KSDownloadModel : GYModelObject
@property (nonatomic, copy) NSString *vid;                  ///< 唯一id标识
@property (nonatomic, copy) NSString *URLString;            ///<  下载地址
@property (nonatomic, copy) NSString *localPath;            ///<  文件存储路径
@property (nonatomic, assign) KSDownloadState state;        ///<  下载状态
@property (nonatomic, strong) NSData *resumeData;           ///<  resumeData
@property (nonatomic, assign) NSUInteger totalFileSize;     ///<  文件总大小
@property (nonatomic, assign) NSUInteger tmpFileSize;       ///<  下载大小
@property (nonatomic, assign) CGFloat progress;             ///<  下载进度
@property (nonatomic, copy) NSString *fileName;             ///<  文件名
@property (nonatomic, assign) NSUInteger lastStateTime;     ///<  最后更新时间
@end
