//
//  HWDownloadButton.h
//  HWProject
//
//  Created by wangqibin on 2018/4/24.
//  Copyright © 2018年 wangqibin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSDownloadModel.h"

@interface HWDownloadButton : UIView

@property (nonatomic, strong) KSDownloadModel *model;  // 数据模型
@property (nonatomic, assign) KSDownloadState state;   // 下载状态
@property (nonatomic, assign) CGFloat progress;        // 下载进度

// 添加点击方法
- (void)addTarget:(id)target action:(SEL)action;

@end

