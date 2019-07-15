//
//  CameraConfigModel.m
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/7/15.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "CameraConfigModel.h"

@implementation CameraConfigModel

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
         isEnableVideoStabilization:(BOOL)isEnableVideoStabilization {
    
    if (self = [super init]) {
        self.previewView = previewView;
        self.preset = preset;
        self.frameRate = frameRate;
        self.resolutionHeight = resolutionHeight;
        self.videoFormat = videoFormat;
        self.torchMode = torchMode;
        self.focusMode = focusMode;
        self.exposureMode = exposureMode;
        self.flashMode = flashMode;
        self.whiteBalanceMode = whiteBalanceMode;
        self.position = position;
        self.videoGravity = videoGravity;
        self.videoOrientation = videoOrientation;
        self.isEnableVideoStabilization = isEnableVideoStabilization;
    }
    return self;
}

@end
