//
//  CameraConfigModel.h
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/7/15.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraConfigModel : NSObject

//预览视图
@property (nonatomic, strong) UIView *previewView;

//AVCaptureSession 设置采集的质量
@property (nonatomic, copy) AVCaptureSessionPreset preset;

//帧率
@property (nonatomic, assign) int frameRate;

//分辨率高度
@property (nonatomic, assign) int resolutionHeight;

//视频格式
@property (nonatomic, assign) OSType videoFormat;

//手电筒类型
@property (nonatomic, assign) AVCaptureTorchMode torchMode;

//聚焦类型
@property (nonatomic, assign) AVCaptureFocusMode focusMode;

//曝光类型
@property (nonatomic, assign) AVCaptureExposureMode exposureMode;

//闪光灯类型
@property (nonatomic, assign) AVCaptureFlashMode flashMode;

//白平衡
@property (nonatomic, assign) AVCaptureWhiteBalanceMode whiteBalanceMode;

//摄像头方向
@property (nonatomic, assign) AVCaptureDevicePosition position;

//分辨率与屏幕尺寸不吻合 时手动计算对焦点策略
@property (nonatomic, copy) AVLayerVideoGravity videoGravity;

//采集方向
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

//视频稳定性调节
@property (nonatomic, assign) BOOL isEnableVideoStabilization;

- (instancetype)initWithPreviewView:(UIView *)previewView
                             preset:(AVCaptureSessionPreset)preset
                          frameRate:(int)frameRate
                   resolutionHeight:(int)resolutionHeight
                        videoFormat:(OSType)videoFormat
                          torchMode:(AVCaptureTorchMode)torchMode
                          focusMode:(AVCaptureFocusMode)focusMode
                       exposureMode:(AVCaptureExposureMode)exposureMode
                          flashMode:(AVCaptureFlashMode)flashMode
                   whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode
                           position:(AVCaptureDevicePosition)position
                       videoGravity:(AVLayerVideoGravity)videoGravity
                   videoOrientation:(AVCaptureVideoOrientation)videoOrientation
         isEnableVideoStabilization:(BOOL)isEnableVideoStabilization;

@end

NS_ASSUME_NONNULL_END
