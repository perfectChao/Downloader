//
//  ViewController.m
//  KSDownloadDemo
//
//  Created by kaishu on 2018/8/22.
//  Copyright © 2018年 kaishu. All rights reserved.
//

#import "ViewController.h"
#import "HWHomeCell.h"
#import "KSDownloader.h"
#import "KSDownloadModel.h"
#import "KSDownloadCache.h"
#import "MJExtension.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray<KSDownloadModel *> *dataSource;
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation ViewController

- (NSMutableArray<KSDownloadModel *> *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    
    return _dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建控件
    [self creatControl];
    
    // 添加通知
    [self addNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 获取网络数据
    [self getInfo];
    
    // 获取缓存
    [self getCacheData];
}

- (void)getInfo
{
    // 模拟网络数据
    NSArray *testData = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"testData.plist" ofType:nil]];
    
    // 转模型
    self.dataSource = [KSDownloadModel mj_objectArrayWithKeyValuesArray:testData];
}

- (void)getCacheData
{
    // 获取已缓存数据
    NSArray *cacheData = [[KSDownloadCache sharedCache] getAllCacheData];
    
    // 这里是把本地缓存数据更新到网络请求的数据中，实际开发还是尽可能避免这样在两个地方取数据再整合
    for (int i = 0; i < self.dataSource.count; i++) {
        KSDownloadModel *model = self.dataSource[i];
        for (KSDownloadModel *downloadModel in cacheData) {
            if (downloadModel.state == KSDownloadStateDownloading) {
                downloadModel.state = KSDownloadStateWaiting; // 杀死客户端状态无法改变bug
            }
            if ([model.URLString isEqualToString:downloadModel.URLString]) {
                self.dataSource[i] = downloadModel;
                break;
            }
        }
    }
    
    [_tableView reloadData];
}

- (void)action0 {
    [[KSDownloader sharedDownloader] startDownloadTasks:self.dataSource];
}

- (void)action1 {
    [[KSDownloader sharedDownloader] suspendAllDownloadTask];
}

- (void)creatControl
{
    UIButton *btn0 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn0.frame = CGRectMake(0, 0, 80, 40);
    btn0.backgroundColor = [UIColor brownColor];
    [btn0 setTitle:@"全部开始" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(action0) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn0];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn1.frame = CGRectMake(200, 0, 80, 40);
    btn1.backgroundColor = [UIColor brownColor];
    [btn1 setTitle:@"全部暂停" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(action1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    // tableView
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height - 50)];
    tableView.showsVerticalScrollIndicator = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 80.f;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    _tableView = tableView;
}

- (void)addNotification
{
    // 进度通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadProgress:) name:KSDownloadProgressNotification object:nil];
    // 状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadStateChange:) name:KSDownloadModelStateChangeNotification object:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HWHomeCell *cell = [HWHomeCell cellWithTableView:tableView];
    
    cell.model = self.dataSource[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - HWDownloadNotification
// 正在下载，进度回调
- (void)downLoadProgress:(NSNotification *)notification
{
    KSDownloadModel *downloadModel = notification.object;

    [self.dataSource enumerateObjectsUsingBlock:^(KSDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.URLString isEqualToString:downloadModel.URLString]) {
            // 主线程更新cell进度
            dispatch_async(dispatch_get_main_queue(), ^{
                HWHomeCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
                [cell updateViewWithModel:downloadModel];
            });

            *stop = YES;
        }
    }];
}

// 状态改变
- (void)downLoadStateChange:(NSNotification *)notification
{
    KSDownloadModel *downloadModel = notification.object;

    [self.dataSource enumerateObjectsUsingBlock:^(KSDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.URLString isEqualToString:downloadModel.URLString]) {
            // 更新数据源
            self.dataSource[idx] = downloadModel;
            
            // 主线程刷新cell
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
            
            *stop = YES;
        }
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
