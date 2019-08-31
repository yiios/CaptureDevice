//
//  SetPushUrlViewController.h
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SetPushUrlViewController : BaseViewController

@property (nonatomic, copy) void(^savePushUrlBlock)(NSString *pushUrl);
@property (nonatomic, copy) NSString *urlStr;

@end

NS_ASSUME_NONNULL_END
