//
//  UITextViewWorkaround.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/11/12.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "UITextViewWorkaround.h"
#import  <objc/runtime.h>

@implementation UITextViewWorkaround

+ (void)executeWorkaround {
    if (@available(iOS 13.2, *)) {
 
    }
    else {
        const char *className = "_UITextLayoutView";
        Class cls = objc_getClass(className);
        if (cls == nil) {
            cls = objc_allocateClassPair([UIView class], className, 0);
            objc_registerClassPair(cls);
#if DEBUG
            printf("added %s dynamically\n", className);
#endif
        }
    }
}

+ (void)exchangePresent {
    [NavBgImage mfa_swizzleInstanceMethod:@selector(presentViewController:animated:completion:) with:@selector(mfa_swizzling_presentViewController:animated:completion:)];
}

- (void)mfa_swizzling_presentViewController:(UIViewController *)viewControllerToPresent
                                   animated: (BOOL)flag
                                 completion:(void (^ __nullable)(void))completion {
    if (@available(iOS 13.0, *)) {
        if (viewControllerToPresent.modalPresentationStyle == UIModalPresentationAutomatic || viewControllerToPresent.modalPresentationStyle == UIModalPresentationPageSheet) {
            viewControllerToPresent.modalPresentationStyle = UIModalPresentationFullScreen;
        } else {
            // Fallback on earlier versions
        };
    }
    [self mfa_swizzling_presentViewController:viewControllerToPresent animated:flag completion:completion];
}


@end
