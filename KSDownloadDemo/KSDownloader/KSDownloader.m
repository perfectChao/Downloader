//
//  KSDownloader.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "KSDownloader.h"
#import <UIKit/UIKit.h>

#import "KSDownloadModel.h"
#import "KSDownloadCache.h"
#import "KSDownloaderTool.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "HWNetworkReachabilityManager.h"

#import "AppDelegate.h"

NSString *const KSDownloadProgressNotification = @"KSDownloadProgressNotification";
NSString *const KSNetworkingReachabilityDidChangeNotification = @"KSNetworkingReachabilityDidChangeNotification";

typedef NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> KSDownloadDictionary;
static const NSInteger KSDownloaderDefaultMaxConcurrentDownloadCount = 1;
static NSString *const KSBackgroundSessionConfigrationIdentifier = @"com.kaishu.downloader.BackgroundSession";

@interface KSDownloader()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, assign) NSInteger maxConcurrentDownloadCount;
@property (nonatomic, strong) KSDownloadDictionary *downloadDict;
@end

@implementation KSDownloader

#pragma mark - Initializer

- (void)dealloc {
    [_session invalidateAndCancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:KSBackgroundSessionConfigrationIdentifier]];
    });
    return instance;
}

+ (void)initialize {
    if (self == [KSDownloader self]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:KSNetworkingReachabilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkingReachabilityDidChange:) name:KSNetworkingReachabilityDidChangeNotification object:nil];
    }
}

- (nonnull instancetype)init {
    @throw [NSException exceptionWithName:@"sharedDownloader init error" reason:@"Use the initWithSessionConfiguration: to init." userInfo:nil];
    return [self initWithSessionConfiguration:nil];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration {
    if ((self = [super init])) {
        _currentCount = 0;
        _maxConcurrentDownloadCount = KSDownloaderDefaultMaxConcurrentDownloadCount;
        _downloadDict = [NSMutableDictionary new];

        [self createNewSessionWithConfiguration:sessionConfiguration];
    }
    return self;
}

- (void)createNewSessionWithConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    if (self.session) {
        [self.session invalidateAndCancel];
    }

    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:queue];
}

#pragma mark - Download Action

- (void)startAllDownloadTask {
    NSArray *unDownloadList = [[KSDownloadCache sharedCache] getAllUnDownloadedData];
    for (KSDownloadModel *m in unDownloadList) {
        [self startDownloadTask:m];
    }
}

- (void)startDownloadTask:(KSDownloadModel *)model {
    KSDownloadModel *downloadModel = [[KSDownloadCache sharedCache] getModelWithURLString:model.URLString];
    if (!downloadModel) {
        downloadModel = model;
        [[KSDownloadCache sharedCache] insertModel:downloadModel];
    }
    
    downloadModel.state = KSDownloadStateWaiting;
    [[KSDownloadCache sharedCache] updateWithModel:downloadModel option:KSCacheUpdateOptionState | KSCacheUpdateOptionLastStateTime];
    
    if (_currentCount < _maxConcurrentDownloadCount && [self networkingAllowsDownloadTask]) {
        [self downloadWithModel:downloadModel];
    }
}

- (void)downloadWithModel:(KSDownloadModel *)model {
    model.state = KSDownloadStateDownloading;
    [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState];
    _currentCount++;
    
    NSURLSessionDownloadTask *downloadTask;
    if (model.resumeData) {
        float version = [[[UIDevice currentDevice] systemVersion] floatValue];
        BOOL needFixBug = (version >= 10.0 && version < 10.2);
        downloadTask = needFixBug ? [_session downloadTaskWithCorrectResumeData:model.resumeData] : [_session downloadTaskWithResumeData:model.resumeData];
    } else {
        downloadTask = [_session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:model.URLString]]];
    }
    downloadTask.taskDescription = model.URLString;
    [_downloadDict setObject:downloadTask forKey:model.URLString];
    [downloadTask resume];
}

- (void)suspendAllDownloadTask {
    [self pauseDownloadingTaskWithAll:YES];
}

- (void)suspendDownloadTask:(KSDownloadModel *)model {
    KSDownloadModel *downloadModel = [[KSDownloadCache sharedCache] getModelWithURLString:model.URLString];
    [self cancelTaskWithModel:downloadModel delete:NO];
    model.state = KSDownloadStatePaused; // update suspend state
    [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState];
}

- (void)deleteTaskAndCache:(KSDownloadModel *)model {
    [self cancelTaskWithModel:model delete:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:model.localPath error:nil];
        [[KSDownloadCache sharedCache] deleteModelWithURLString:model.URLString];
    });
}

- (void)cancelTaskWithModel:(KSDownloadModel *)model delete:(BOOL)delete {
    if (model.state == KSDownloadStateDownloading) {
        NSURLSessionDownloadTask *downloadTask = [_downloadDict valueForKey:model.URLString];
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            model.resumeData = resumeData;
            [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionResumeData];
            if (self.currentCount > 0) self.currentCount--;
            [self startDownloadWaitingTask];
        }];
        
        if (delete) [_downloadDict removeObjectForKey:model.URLString];
    }
}

- (void)startDownloadWaitingTask {
    if (_currentCount < _maxConcurrentDownloadCount && [self networkingAllowsDownloadTask]) {
        KSDownloadModel *model = [[KSDownloadCache sharedCache] getWaitingModel];
        if (model) {
            [self downloadWithModel:model];
            [self startDownloadWaitingTask];
        }
    }
}

- (void)pauseDownloadingTaskWithAll:(BOOL)all {
    NSArray *downloadingData = [[KSDownloadCache sharedCache] getAllDownloadingData];
    NSInteger count = all ? downloadingData.count : downloadingData.count - _maxConcurrentDownloadCount;
    for (NSInteger i = 0; i < count; i++) {
        KSDownloadModel *model = downloadingData[i];
        [self cancelTaskWithModel:model delete:NO];
        
        model.state = KSDownloadStateWaiting; // update waiting state
        [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState];
    }
}

- (void)updateDownloadingTaskState {
    NSArray *downloadingData = [[KSDownloadCache sharedCache] getAllDownloadingData];
    for (KSDownloadModel *model in downloadingData) {
        model.state = KSDownloadStateWaiting;
        [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState];
    }
}

- (void)openDownloadTask {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startDownloadWaitingTask];
    });
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    KSDownloadModel *model = [[KSDownloadCache sharedCache] getModelWithURLString:downloadTask.taskDescription];
    model.tmpFileSize = totalBytesWritten;
    model.totalFileSize = totalBytesExpectedToWrite;
    model.progress = 1.0 * model.tmpFileSize / model.totalFileSize;
    [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionProgressData];
    ks_dispatch_async_on_main_queue(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KSDownloadProgressNotification object:model];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    KSDownloadModel *model = [[KSDownloadCache sharedCache] getModelWithURLString:downloadTask.taskDescription];
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:model.localPath error:&error];
    if (error) NSLog(@"下载完成，移动文件发生错误：%@", error);
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && [error.localizedDescription isEqualToString:@"cancelled"]) return;
    
    KSDownloadModel *model = [[KSDownloadCache sharedCache] getModelWithURLString:task.taskDescription];
    if (error && [error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey]) {
        model.state = KSDownloadStateWaiting;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState | KSCacheUpdateOptionResumeData];
        return;
    }
    
    if (error) {
        model.state = KSDownloadStateError;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionResumeData];
    } else {
        model.state = KSDownloadStateFinish;
    }
    
    if (_currentCount > 0) _currentCount--;
    [_downloadDict removeObjectForKey:model.URLString];
    
    [[KSDownloadCache sharedCache] updateWithModel:model option:KSCacheUpdateOptionState];
    
    [self startDownloadWaitingTask];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.backgroundSessionCompletionHandler) {
            void (^completionHandler)(void) = appDelegate.backgroundSessionCompletionHandler;
            appDelegate.backgroundSessionCompletionHandler = nil;
            completionHandler();
        }
    });
}

#pragma mark - NSNotification

- (void)networkingReachabilityDidChange:(NSNotification *)notification {
    [self allowsCellularAccessOrNetworkingReachabilityDidChangeAction];
}

- (void)allowsCellularAccessOrNetworkingReachabilityDidChangeAction {
    if ([self networkingAllowsDownloadTask]) {
        [self startDownloadWaitingTask];
    } else {
        // 当网络不可到达时, 将所有任务切换到等待状态, 待网络恢复后继续下载
        [self pauseDownloadingTaskWithAll:YES];
    }
}

- (BOOL)networkingAllowsDownloadTask {
    // TODO: 添加网络判断是否可达
    return YES;
}

@end
