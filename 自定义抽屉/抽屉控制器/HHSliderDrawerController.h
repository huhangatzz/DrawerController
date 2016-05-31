//
//  HU_SliderDrawerController.h
//  抽屉
//
//  Created by huhang on 15/11/13.
//  Copyright (c) 2015年 huhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HHSliderDrawerController : UIViewController

/**
 *  初始化方法
 *
 *  @param rootViewController 根视图控制器
 *  @param leftViewController 左视图控制器
 *
 *  @return
 */
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController leftViewController:(UIViewController *)leftViewController;

/** 抽屉宽度 */
@property (nonatomic,assign)CGFloat leftViewShowWidth;

/** 动画持续时间 */
@property (nonatomic,assign)NSTimeInterval animationDuration;

/** 展示左视图 */
- (void)showLeftViewController:(BOOL)animated;

@end
