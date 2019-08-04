//
//  UIView+HUD.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "UIView+HUD.h"
#import <Toast/Toast.h>


@implementation UIView (HUD)

- (void)showHint:(NSString *)hint {
    if (hint.length > 0) {
        [CSToastManager setQueueEnabled:NO];
        [self makeToast:hint duration:1.0 position:CSToastPositionCenter];
    }
}

- (void)showHintOnWindow:(NSString *)hint {
    if (hint.length > 0) {
        [CSToastManager setQueueEnabled:NO];
        [[self.class windowForHud] makeToast:hint duration:1.0 position:CSToastPositionCenter];
    }
}

+ (UIWindow *)windowForHud {
    return [[UIApplication sharedApplication].delegate window];
}

@end
