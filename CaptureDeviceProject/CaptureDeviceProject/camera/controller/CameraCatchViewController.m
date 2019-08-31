//
//  CameraCatchViewController.m
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/7/15.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "CameraCatchViewController.h"
#import "CameraCatchHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <ReplayKit/ReplayKit.h>

@interface CameraCatchViewController ()

@end

@implementation CameraCatchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [self configCamera];
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.gunmm.CaptureDeviceProject"];
    [userDefaults setObject:@"http://www.baidu.com" forKey:@"rtmpPushUrl"];
}

- (void)configCamera {
    CameraConfigModel *cameraConfigModel = [[CameraConfigModel alloc] initWithPreviewView:self.view
                                                                                   preset:AVCaptureSessionPreset1280x720
                                                                                frameRate:30
                                                                         resolutionHeight:720
                                                                              videoFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                                                                                torchMode:AVCaptureTorchModeOff
                                                                                focusMode:AVCaptureFocusModeLocked
                                                                             exposureMode:AVCaptureExposureModeContinuousAutoExposure
                                                                                flashMode:AVCaptureFlashModeAuto
                                                                         whiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance
                                                                                 position:AVCaptureDevicePositionBack
                                                                             videoGravity:AVLayerVideoGravityResizeAspect
                                                                         videoOrientation:AVCaptureVideoOrientationLandscapeRight
                                                               isEnableVideoStabilization:YES];
    
    CameraCatchHandler *cameraCatchHandler = [CameraCatchHandler new];
    [cameraCatchHandler configWithCameraConfigModel:cameraConfigModel];
    [cameraCatchHandler startRunning];
}

- (IBAction)beginBtnAct:(id)sender {

    if (@available(iOS 12.0, *)) {
        RPSystemBroadcastPickerView *_broadPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:self.view.bounds];
        _broadPickerView.preferredExtension = @"gunmm.CaptureDeviceProject.ScreenCapture";
        [self.view addSubview:_broadPickerView];
    } else {
        // Fallback on earlier versions
    }
  
   
}



@end
