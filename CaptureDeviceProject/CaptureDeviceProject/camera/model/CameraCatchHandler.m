//
//  CameraCatchHandler.m
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/7/15.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "CameraCatchHandler.h"
#import <AVFoundation/AVFoundation.h>

@interface CameraCatchHandler () <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation CameraCatchHandler

- (void)startRunning {
    [self.session startRunning];
}

- (void)stopRunning {
    [self.session stopRunning];
}

- (void)configWithCameraConfigModel:(CameraConfigModel *)model {
    NSError *error = nil;
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    //AVCaptureSession 设置采集的质量
    session.sessionPreset = model.preset;
    
    // Set frame rate and resolution
    [CameraCatchHandler setCameraFrameRateAndResolutionWithFrameRate:model.frameRate
                                               andResolutionHeight:model.resolutionHeight
                                                         bySession:session
                                                          position:model.position
                                                       videoFormat:model.videoFormat];
    
    
    AVCaptureDevice *device = [CameraCatchHandler getCaptureDevicePosition:model.position];
    
    
    // Set flash mode
    if ([device hasFlash]){
        if (@available(iOS 10.0, *)) {
            NSArray *outputs = session.outputs;
            for (AVCaptureOutput *output in outputs) {
                if ([output isMemberOfClass:[AVCapturePhotoOutput class]]) {
                    AVCapturePhotoOutput *photoOutput = (AVCapturePhotoOutput *)output;
                    BOOL flashSupported = [[photoOutput supportedFlashModes] containsObject:@(model.flashMode)];
                    if (flashSupported) {
                        AVCapturePhotoSettings *photoSettings = photoOutput.photoSettingsForSceneMonitoring;
                        photoSettings.flashMode = AVCaptureFlashModeAuto;
                    }else {
                        NSLog(@"The device not support current flash mode : %ld!",model.flashMode);
                    }
                }
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            if ([device isFlashModeSupported:model.flashMode]) {
                [device setFlashMode:model.flashMode];
            }else {
                NSLog(@"The device not support current flash mode : %ld!",model.flashMode);
            }
#pragma clang diagnostic pop
        }
    }else {
        NSLog(@"The device not support flash!");
    }
    
    //Set white balance mode
    if ([device isWhiteBalanceModeSupported:model.whiteBalanceMode]) {
        [device lockForConfiguration:nil];
        [device setWhiteBalanceMode:model.whiteBalanceMode];
        [device unlockForConfiguration];

    }else {
        NSLog(@"The device not support current white balance mode : %ld!",model.whiteBalanceMode);
    }
    
    // Add input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error != noErr) {
        NSLog(@"Configure device input failed:%@",error.localizedDescription);
        return;
    }
    [session addInput:input];
    
    // Conigure and add output
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [session addOutput:videoDataOutput];
    [session addOutput:audioDataOutput];
    
    videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:model.videoFormat]
                                                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    
    // Use serial queue to receive audio / video data
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
    dispatch_queue_t audioQueue = dispatch_queue_create("audioQueue", NULL);
    [audioDataOutput setSampleBufferDelegate:self queue:audioQueue];
    [videoDataOutput setSampleBufferDelegate:self queue:videoQueue];
    
    // Set video Stabilization
//    if (model.isEnableVideoStabilization) {
//        [self adjustVideoStabilizationWithOutput:videoDataOutput];
//    }
    
    // Set video preview
    CALayer *previewViewLayer = [model.previewView layer];
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewViewLayer.backgroundColor = [[UIColor blackColor] CGColor];
    CGRect frame = [previewViewLayer bounds];
    NSLog(@"previewViewLayer = %@",NSStringFromCGRect(frame));
    
    [videoPreviewLayer setFrame:model.previewView.frame];
    [videoPreviewLayer setVideoGravity:model.videoGravity];
    
    if([[videoPreviewLayer connection] isVideoOrientationSupported]) {
        [videoPreviewLayer.connection setVideoOrientation:model.videoOrientation];
    }else {
        NSLog(@"Not support video Orientation!");
    }
    
    [previewViewLayer insertSublayer:videoPreviewLayer atIndex:0];
    self.session = session;
    
}

+ (BOOL)setCameraFrameRateAndResolutionWithFrameRate:(int)frameRate andResolutionHeight:(CGFloat)resolutionHeight bySession:(AVCaptureSession *)session position:(AVCaptureDevicePosition)position videoFormat:(OSType)videoFormat {
    AVCaptureDevice *captureDevice = [self getCaptureDevicePosition:position];
    
    BOOL isSuccess = NO;
    for (AVCaptureDeviceFormat *vFormat in [captureDevice formats]) {
        CMFormatDescriptionRef description = vFormat.formatDescription;
        float maxRate = ((AVFrameRateRange *)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        if (maxRate >= frameRate && CMFormatDescriptionGetMediaSubType(description) == videoFormat) {
            CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(description);
            if (dims.height == resolutionHeight && dims.width == [self getResolutionWidthByHeight:resolutionHeight]) {
                [session beginConfiguration];
                if ([captureDevice lockForConfiguration:nil]) {
                    captureDevice.activeFormat = vFormat;
                    [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, frameRate)];
                    [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, frameRate)];
                    [captureDevice unlockForConfiguration];
                } else {
                    NSLog(@"%s: lock failed!",__func__);
                }
                [session commitConfiguration];
                return YES;
            }
        }
    }
    
    NSLog(@"Set camera frame is success : %d, frame rate is %lu, resolution height = %f",isSuccess,(unsigned long)frameRate,resolutionHeight);
    return NO;
}

+ (AVCaptureDevice *)getCaptureDevicePosition:(AVCaptureDevicePosition)position {
    NSArray *devices = nil;
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                                                         mediaType:AVMediaTypeVideo
                                                                                                                          position:position];
        devices = deviceDiscoverySession.devices;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
#pragma clang diagnostic pop
    }
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return NULL;
}


+ (int)getResolutionWidthByHeight:(int)height {
    switch (height) {
        case 2160:
            return 3840;
        case 1080:
            return 1920;
        case 720:
            return 1280;
        case 480:
            return 640;
        default:
            return -1;
    }
}


#pragma mark - Delegate
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([output isKindOfClass:[AVCaptureVideoDataOutput class]] == YES) {
        NSLog(@"Error: Drop video frame");
    }else {
        NSLog(@"Error: Drop audio frame");
    }
    
//    if ([self.delegate respondsToSelector:@selector(xdxCaptureOutput:didDropSampleBuffer:fromConnection:)]) {
//        [self.delegate xdxCaptureOutput:output didDropSampleBuffer:sampleBuffer fromConnection:connection];
//    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    
    if ([output isKindOfClass:[AVCaptureVideoDataOutput class]] == YES) {
//        [self calculatorCaptureFPS];
        CVPixelBufferRef pix  = CMSampleBufferGetImageBuffer(sampleBuffer);
//        self.realTimeResolutionWidth  = (int)CVPixelBufferGetWidth(pix);
//        self.realTimeResolutionHeight = (int)CVPixelBufferGetHeight(pix);
//
        //        NSLog(@"%d---------%d", (int)CVPixelBufferGetWidth(pix), (int)CVPixelBufferGetHeight(pix));
        // NSLog(@"capture: video data");
    }else if ([output isKindOfClass:[AVCaptureAudioDataOutput class]] == YES) {
        // NSLog(@"capture: audio data");
    }
    
//    if ([self.delegate respondsToSelector:@selector(xdxCaptureOutput:didOutputSampleBuffer:fromConnection:)]) {
//        [self.delegate xdxCaptureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
//    }
}


@end
