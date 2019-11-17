//
//  NavBgImage.h
//  wiseCloudCrm
//
//  Created by 闵哲 on 16/7/18.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NavBgImage : UIImage

+ (BOOL)mfa_swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel;

+ (UIImage *)imageWithImage:(UIImage *)image TintColor:(UIColor *)tintColor;

//用颜色创建图片
+ (UIImage *)createImageWithColor:(UIColor*) color;

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC;

+ (void)showGoogleIconForView:(UIView *)view iconName:(NSString *)iconName color:(UIColor *)iconColor font:(CGFloat)iconFont suffix:(NSString *)suffix;


+ (UIColor *)getColorByString:(NSString *)str;

+ (void)showIconFontForView:(UIView *)view iconName:(NSString *)iconName color:(UIColor *)iconColor font:(CGFloat)iconFont;

#pragma mark---------判断当前显示VC是不是模态视图
//判断当前显示VC是不是模态视图
+ (BOOL)judgeCurrentVCIspresented;



@end
