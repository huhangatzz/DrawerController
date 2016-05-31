//
//  HU_SliderDrawerController.m
//  抽屉
//
//  Created by huhang on 15/11/13.
//  Copyright (c) 2015年 huhang. All rights reserved.
//

#import "HHSliderDrawerController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface HHSliderDrawerController ()<UIGestureRecognizerDelegate>

/** 根视图控制器 */
@property (nonatomic,strong)UIViewController  *rootViewController;
/** 左侧视图控制器 */
@property (nonatomic,strong)UIViewController  *leftViewController;

/** 根控制器视图 */
@property (nonatomic,strong)UIView            *currentView;
/** 拖动手势 */
@property (nonatomic,strong)UIPanGestureRecognizer   *panGestureRecognizer;
/** 覆盖button */
@property (nonatomic,strong)UIButton                 *coverButton;
/** 开始时pan的点位置 */
@property (nonatomic,assign)CGPoint                  startPanPoint;
/** yes 是向右,no是向左 */
@property (nonatomic,assign)BOOL                     panMovingRightOrLeft;

@end

@implementation HHSliderDrawerController

#pragma mark init方法
- (instancetype)init{
    
    if (self = [super init]) {
        //添加手势
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
        [_panGestureRecognizer setDelegate:self];
        [self.view addGestureRecognizer:_panGestureRecognizer];
        
        //覆盖button
       UIButton *coverButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
       coverButton.backgroundColor = [UIColor clearColor];
       coverButton.alpha = 0.3;
       [coverButton addTarget:self action:@selector(hideSideViewController) forControlEvents:UIControlEventTouchUpInside];
        self.coverButton = coverButton;
    }
    return self;
}

#pragma mark 初始化方法
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController leftViewController:(UIViewController *)leftViewController{
    
    self = [[HHSliderDrawerController alloc]init];
    if (self) {
        _rootViewController = rootViewController;
        _leftViewController = leftViewController;
        [self resetCurrentViewToRootViewController];
    }
    return self;
}

#pragma mark 设置当前视图为根视图
- (void)resetCurrentViewToRootViewController{
    
    //目前视图就是根视图控制器的视图
    UIView *currentView = _rootViewController.view;
    currentView.frame = self.view.bounds;
    [self.view addSubview:currentView];
    self.currentView = currentView;
    
    //添加为子控制器
    [self addChildViewController:_rootViewController];
    [self addChildViewController:_leftViewController];
    
    _leftViewShowWidth = 200;
    _animationDuration = 1;
    _panMovingRightOrLeft = YES;
}

#pragma mark 手势代理方法
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
   
    //是否开启手势
    if (gestureRecognizer == _panGestureRecognizer) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer*)gestureRecognizer;
        CGPoint translation = [panGesture translationInView:self.view];
        if ([panGesture velocityInView:self.view].x < 600 && ABS(translation.x) / ABS(translation.y) > 1) {
            return YES;
        }
        return NO;
    }
    return YES;
}

#pragma mark 手势响应方法
- (void)pan:(UIPanGestureRecognizer *)panGesture{
    
    CGPoint velocity = [panGesture velocityInView:self.view];
    
    //开始时
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        //记录开始值
        _startPanPoint = _currentView.frame.origin;
        if (_startPanPoint.x == 0) {
            [self showShadow:YES];
        }
        
        if(velocity.x > 0){//向右滑动时将要展示左视图
           [self willShowLeftViewController];
        }
    }
    
    //改变时
    if (panGesture.state == UIGestureRecognizerStateChanged){
        
        //手势滑动的位置
        CGPoint currentPostion = [panGesture translationInView:self.view];
        //滑动开始时候的位置
        CGFloat xoffset = _startPanPoint.x + currentPostion.x;
        
        if (xoffset > 0) {//向右滑动
            //如果滑动开始的位置大于设置左视图的宽度,就等于左视图的宽度
            xoffset = (xoffset >= _leftViewShowWidth) ? _leftViewShowWidth : xoffset;
        }else if(xoffset < 0){//向左滑
            xoffset = 0;
        }
        
        if (xoffset != _leftViewShowWidth) {
            //不相等就一直移动到相等为止
            [self layoutCurrentViewWithOffset:xoffset];
        }
        
        //移动速度大于0,说明是往右移动
        if (velocity.x > 0) {
            _panMovingRightOrLeft = YES;
        }else if(velocity.x < 0){
            //移动速度小于0,说明是往左移动
            _panMovingRightOrLeft = NO;
        }
    }
    
    //结束时
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        
        if (_currentView.frame.origin.x == 0) {
            //取消阴影
            [self showShadow:NO];
            //覆盖的button也移除
            [_coverButton removeFromSuperview];
        }else{
            
            if (_panMovingRightOrLeft && _currentView.frame.origin.x > 40) {
                //展示左视图
                [self showLeftViewController:YES];
            }else if(!_panMovingRightOrLeft && _currentView.frame.origin.x < 0){
                //表示向左移动
            }else{
                //收回抽屉
                [self hideSideViewController];
            }
        }
    }
}

#pragma mark 将要展示左视图
- (void)willShowLeftViewController{
    _leftViewController.view.frame = self.view.bounds;
    //把左视图插入到根视图下面
    [self.view insertSubview:_leftViewController.view belowSubview:_currentView];
}

#pragma mark 打开左视图
- (void)showLeftViewController:(BOOL)animated{
    
    NSTimeInterval animatedTime = 0;
    if (animated) {
        animatedTime = ABS(_leftViewShowWidth - _currentView.frame.origin.x) / _leftViewShowWidth * _animationDuration;
    }
    [UIView animateWithDuration:animatedTime animations:^{
        //这个方法把抽屉拉动自定义宽度
        [self layoutCurrentViewWithOffset:_leftViewShowWidth];
        [self.currentView addSubview:_coverButton];
        [self showShadow:YES];
    }];
}

#pragma mark 隐藏左视图
- (void)hideSideViewController:(BOOL)animated{
    
    NSTimeInterval animatedTime = 0;
    if (animated) {
        animatedTime = ABS(_currentView.frame.origin.x / (_currentView.frame.origin.x > 0 ? _leftViewShowWidth : 0)) * _animationDuration;
    }
    [UIView animateWithDuration:animatedTime animations:^{
        //设置抽屉宽度为0
        [self layoutCurrentViewWithOffset:0];
        
    } completion:^(BOOL finished) {
        //移除button和左视图及阴影
        [_coverButton removeFromSuperview];
        [_leftViewController.view removeFromSuperview];
        [self showShadow:NO];
    }];
}

#pragma mark 重写此方法可以改变动画效果
- (void)layoutCurrentViewWithOffset:(CGFloat)xoffset{
    
    self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(xoffset, 0);
    self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(xoffset, 0);
    
    //平行移动
    [_currentView setFrame:CGRectMake(xoffset, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
}

#pragma mark 展示阴影
- (void)showShadow:(BOOL)isShow{
    //显示阴影深度
    _currentView.layer.shadowOpacity = isShow ? 0.8f : 0.0f;
    if (isShow) {
        self.currentView.layer.cornerRadius = 4.0f;
        self.currentView.layer.shadowOffset = CGSizeZero;
        self.currentView.layer.shadowRadius = 4.0f;
    }
}

//点击button响应方法
- (void)hideSideViewController{
    [self hideSideViewController:YES];
}

- (void)setLeftViewShowWidth:(CGFloat)leftViewShowWidth{
    _leftViewShowWidth = leftViewShowWidth;
}

- (void)setAnimationDuration:(NSTimeInterval)animationDuration{
    _animationDuration = animationDuration;
}

@end
