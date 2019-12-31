//
//  PayManager.h
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/12/27.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PayManager : NSObject

+ (instancetype)manager;

//请求商品
- (void)getRequestAppleProduct;

@end

NS_ASSUME_NONNULL_END
