//
//  UIView+HUD.h
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HUD)

- (void)showHint:(NSString *)hint;
- (void)showHintOnWindow:(NSString *)hint;

@end

NS_ASSUME_NONNULL_END
