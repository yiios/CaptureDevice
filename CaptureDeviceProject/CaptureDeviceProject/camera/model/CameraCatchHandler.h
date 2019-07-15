//
//  CameraCatchHandler.h
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/7/15.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraCatchHandler : NSObject

- (void)startRunning;
- (void)stopRunning;
- (void)configWithCameraConfigModel:(CameraConfigModel *)model;

@end

NS_ASSUME_NONNULL_END
