//
//  SampleHandler.m
//  ScreenCapture
//
//  Created by minzhe on 2019/7/31.
//  Copyright © 2019 minzhe. All rights reserved.
//


#import "SampleHandler.h"
#import <LFLiveKit/LFLiveKit.h>
#import <UIKit/UIKit.h>

@interface SampleHandler () <LFStreamSocketDelegate, LFVideoEncodingDelegate>

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) id<LFStreamSocket> socket;
@property (nonatomic, strong) LFLiveStreamInfo *streamInfo;

@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;
/// 音频配置
@property (nonatomic, strong) LFLiveAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) LFLiveVideoConfiguration *videoConfiguration;



@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, assign) uint64_t relativeTimestamps;

@property (nonatomic, assign) BOOL canUpload;

@property (nonatomic, strong) dispatch_queue_t rotateQueue;
@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) LFVideoFrame *lastRecordFrame;
@property (nonatomic, assign) uint64_t lastTimeSpace;
@property (nonatomic, strong) CIImage *lastCIImage;
@property (nonatomic, assign) size_t lastWidth;
@property (nonatomic, assign) size_t lastHeight;
@property (nonatomic, assign) uint64_t lastTime;

@property (nonatomic, assign) UIInterfaceOrientation encoderOrientation;
@property (nonatomic, assign) CGImagePropertyOrientation rotateOrientation;

@end

@implementation SampleHandler

- (LFLiveStreamInfo *)streamInfo {
    if (!_streamInfo) {
        _streamInfo = [[LFLiveStreamInfo alloc] init];
        _streamInfo.url = [_userDefaults objectForKey:@"urlStr"];
    }
    
    return _streamInfo;
}

- (id<LFStreamSocket>)socket {
    if (!_socket) {
        _socket = [[LFStreamRTMPSocket alloc] initWithStream:self.streamInfo reconnectInterval:0 reconnectCount:0];
        [_socket setDelegate:self];
    }
    return _socket;
}

- (id<LFVideoEncoding>)videoEncoder {
    if (!_videoEncoder) {
        _videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:self.videoConfiguration];
        [_videoEncoder setDelegate:self];
    }
    return _videoEncoder;
}

- (LFLiveVideoConfiguration *)videoConfiguration {
    if (!_videoConfiguration) {
        _videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High3 outputImageOrientation:self.encoderOrientation];
    }
    return _videoConfiguration;
}

- (UIInterfaceOrientation)encoderOrientation {
    NSInteger screenOrientationValue = [[_userDefaults objectForKey:@"screenOrientationValue"] integerValue];
    UIInterfaceOrientation orientationValue = UIInterfaceOrientationPortrait;
    switch (screenOrientationValue) {
        case 1:
            orientationValue = UIInterfaceOrientationLandscapeRight;
            break;
        case 2:
            orientationValue = UIInterfaceOrientationLandscapeLeft;
            break;
        default:
            break;
    }
    return orientationValue;
}

- (CGImagePropertyOrientation)rotateOrientation {
    NSInteger screenOrientationValue = [[_userDefaults objectForKey:@"screenOrientationValue"] integerValue];
    CGImagePropertyOrientation rotateOrientation = kCGImagePropertyOrientationUp;
    switch (screenOrientationValue) {
        case 1:
            rotateOrientation = kCGImagePropertyOrientationLeft;
            break;
        case 2:
            rotateOrientation = kCGImagePropertyOrientationRight;
            break;
        default:
            break;
    }
    return rotateOrientation;
}


- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.gunmm.CaptureDeviceProject"];
    self.rotateQueue = dispatch_queue_create("rotateQueue", nil);
    [self.socket start];
    _ciContext = [CIContext contextWithOptions:nil];
    
    __weak typeof(self) weakSelf = self;
    CADisplayLink *_link = [CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(checkFPS:)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)checkFPS:(CADisplayLink *)link {
    if (!self.canUpload) {
        return;
    }
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }

    NSTimeInterval delta = link.timestamp - _lastTime;
    if (delta < 2) return;
    _lastTime = link.timestamp;
    if (_lastTimeSpace == 0) {
        _lastTimeSpace = _lastRecordFrame.timestamp;
        return;
    }
    if (_lastTimeSpace == _lastRecordFrame.timestamp) {
        __weak typeof(self) wSelf = self;
        dispatch_async(wSelf.rotateQueue, ^{
            [wSelf dealWithLastCIImage:wSelf.lastCIImage];
        });
        NSLog(@"*****************************");
    }
    _lastTimeSpace = _lastRecordFrame.timestamp;
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"------Paused-------");

}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"------Resumed-------");

}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"------Finished-------");
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
        {
            if (self.canUpload) {
                __weak typeof(self) wSelf = self;
                CFRetain(sampleBuffer);
                dispatch_async(wSelf.rotateQueue, ^{
                    [wSelf dealWithSampleBuffer:sampleBuffer];
                    CFRelease(sampleBuffer);
                });
            }
        }
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
//            NSLog(@"----AudioApp------");

            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
//            NSLog(@"----AudioMic------");

            break;
            
        default:
            break;
    }
}

- (uint64_t)uploadTimestamp:(uint64_t)captureTimestamp{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    return currentts;
}

- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame {
    if (self.canUpload){
        [self pushSendBuffer:frame];
        self.lastRecordFrame = frame;
    }
}

#pragma mark -- PrivateMethod
- (void)pushSendBuffer:(LFFrame*)frame{
    if(self.relativeTimestamps == 0){
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestamp:frame.timestamp];
    [self.socket sendFrame:frame];
}

#pragma mark -- LFStreamTcpSocketDelegate
- (void)socketStatus:(nullable id<LFStreamSocket>)socket status:(LFLiveState)status {
    NSLog(@"--------%lu", status);
    if (status == LFLiveError) {
        NSLog(@"111");
    }
    
    if (status == LFLiveStart) {
        self.canUpload = YES;
    } else {
        self.canUpload = NO;
    }
}

- (void)socketDidError:(nullable id<LFStreamSocket>)socket errorCode:(LFLiveSocketErrorCode)errorCode {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:errorCode:)]) {
    //            [self.delegate liveSession:self errorCode:errorCode];
    //        }
    //    });
}

- (void)socketDebug:(nullable id<LFStreamSocket>)socket debugInfo:(nullable LFLiveDebug *)debugInfo {
    //    self.debugInfo = debugInfo;
    //    if (self.showDebugInfo) {
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:debugInfo:)]) {
    //                [self.delegate liveSession:self debugInfo:debugInfo];
    //            }
    //        });
    //    }
}

- (void)socketBufferStatus:(nullable id<LFStreamSocket>)socket status:(LFLiveBuffferState)status {
    NSLog(@"LFLiveBuffferState---  %ld", status);
    NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
    if (status == LFLiveBuffferDecline) {
        if (videoBitRate < _videoConfiguration.videoMaxBitRate) {
            videoBitRate = videoBitRate + 50 * 1000;
            [self.videoEncoder setVideoBitRate:videoBitRate];
            NSLog(@"Increase bitrate %@", @(videoBitRate));
        }
    } else {
        if (videoBitRate > self.videoConfiguration.videoMinBitRate) {
            videoBitRate = videoBitRate - 100 * 1000;
            [self.videoEncoder setVideoBitRate:videoBitRate];
            NSLog(@"Decline bitrate %@", @(videoBitRate));
        }
    }
}

- (void)dealWithSampleBuffer:(CMSampleBufferRef)buffer {
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);
    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    self.lastCIImage = ciimage;
    self.lastWidth = width;
    self.lastHeight = height;
    NSLog(@"----%zu,   %zu", width, height);
    
    if (self.rotateOrientation == kCGImagePropertyOrientationUp) {
        [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:(CACurrentMediaTime()*1000)];
    } else {
        // 旋转的方法
        CIImage *wImage = [ciimage imageByApplyingCGOrientation:self.rotateOrientation];
        
        CIImage *newImage = [wImage imageByApplyingTransform:CGAffineTransformMakeScale(1, 1)];
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRef newPixcelBuffer = nil;
        CVPixelBufferCreate(kCFAllocatorDefault, height, width, kCVPixelFormatType_32BGRA, nil, &newPixcelBuffer);
        [_ciContext render:newImage toCVPixelBuffer:newPixcelBuffer];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        [self.videoEncoder encodeVideoData:newPixcelBuffer timeStamp:(CACurrentMediaTime()*1000)];
        CVPixelBufferRelease(newPixcelBuffer);
    }
}

- (void)dealWithLastCIImage:(CIImage *)lastCIImage {
    // 旋转的方法
    NSLog(@"------------------补帧方法---------------------");
    CIImage *wImage;
    if (self.rotateOrientation == kCGImagePropertyOrientationUp) {
        wImage = [lastCIImage imageByApplyingCGOrientation:self.rotateOrientation];
    } else {
        wImage = lastCIImage;
    }
    CIImage *newImage = [wImage imageByApplyingTransform:CGAffineTransformMakeScale(1, 1)];
    CVPixelBufferRef newPixcelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault, self.lastHeight, self.lastWidth, kCVPixelFormatType_32BGRA, nil, &newPixcelBuffer);
    [_ciContext render:newImage toCVPixelBuffer:newPixcelBuffer];
    [self.videoEncoder encodeVideoData:newPixcelBuffer timeStamp:(CACurrentMediaTime()*1000)];
    CVPixelBufferRelease(newPixcelBuffer);
}

@end
