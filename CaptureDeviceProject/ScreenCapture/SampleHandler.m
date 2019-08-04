//
//  SampleHandler.m
//  ScreenCapture
//
//  Created by minzhe on 2019/7/31.
//  Copyright © 2019 minzhe. All rights reserved.
//


#import "SampleHandler.h"
#import <LFLiveKit/LFLiveKit.h>

@interface SampleHandler () <LFStreamSocketDelegate, LFVideoEncodingDelegate>

@property (nonatomic, strong) id<LFStreamSocket> socket;

@property (nonatomic, strong) LFLiveStreamInfo *streamInfo;

@property (nonatomic, strong) dispatch_semaphore_t lock;

@property (nonatomic, assign) uint64_t relativeTimestamps;

@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;

@property (nonatomic, assign) BOOL canUpload;

@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) LFVideoFrame *oldRecordFrame;
@property (nonatomic, strong) LFVideoFrame *newrecordFrame;

@property (nonatomic, strong) NSTimer *timer;
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
        _videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:[LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_Medium3 outputImageOrientation:UIInterfaceOrientationLandscapeRight]];
        [_videoEncoder setDelegate:self];
    }
    
  
    return _videoEncoder;
}


- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.gunmm.CaptureDeviceProject"];
    [self.socket start];
    _ciContext = [CIContext contextWithOptions:nil];
    __weak typeof(self) weakSelf = self;
////    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkFPS) userInfo:nil repeats:YES];
////    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
////    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.
//                                             target:self
//                                           selector:@selector(checkFPS:)
//                                           userInfo:nil
//                                            repeats:YES];
    
    TestTimer *testT = [TestTimer new];
    [testT beginTimer];
}


- (void)checkFPS:(NSTimer *)timer {
    if (self.oldRecordFrame.timestamp == self.newrecordFrame.timestamp) {
        NSLog(@"s**********补帧了");
        [self pushSendBuffer:self.newrecordFrame];
    }
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
            // Handle video sample buffer
//            NSLog(@"----RPSampleBufferTypeVideo------");
            [self dealWithSampleBuffer:sampleBuffer];
            
//            if (self.canUpload) {

//            }
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
    //上传 时间戳对齐
//    if (self.uploading){
    [self pushSendBuffer:frame];
    self.oldRecordFrame = self.newrecordFrame;
    self.newrecordFrame = frame;
    
//    }
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
    //    if((self.captureType & LFLiveCaptureMaskVideo || self.captureType & LFLiveInputMaskVideo) && self.adaptiveBitrate){
    //        NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
    //        if (status == LFLiveBuffferDecline) {
    //            if (videoBitRate < _videoConfiguration.videoMaxBitRate) {
    //                videoBitRate = videoBitRate + 50 * 1000;
    //                [self.videoEncoder setVideoBitRate:videoBitRate];
    //                NSLog(@"Increase bitrate %@", @(videoBitRate));
    //            }
    //        } else {
    //            if (videoBitRate > self.videoConfiguration.videoMinBitRate) {
    //                videoBitRate = videoBitRate - 100 * 1000;
    //                [self.videoEncoder setVideoBitRate:videoBitRate];
    //                NSLog(@"Decline bitrate %@", @(videoBitRate));
    //            }
    //        }
    //    }
}

- (void)dealWithSampleBuffer:(CMSampleBufferRef)buffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);
    
    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    size_t width                        = CVPixelBufferGetWidth(pixelBuffer);
    size_t height                       = CVPixelBufferGetHeight(pixelBuffer);
    NSLog(@"----%zu,   %zu", width, height);
    // 旋转的方法
    CIImage *wImage = [ciimage imageByApplyingCGOrientation:kCGImagePropertyOrientationLeft];
    
    CIImage *newImage = [wImage imageByApplyingTransform:CGAffineTransformMakeScale(1, 1)];
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRef newPixcelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault, height, width, kCVPixelFormatType_32BGRA, nil, &newPixcelBuffer);
    [_ciContext render:newImage toCVPixelBuffer:newPixcelBuffer];
    [self.videoEncoder encodeVideoData:newPixcelBuffer timeStamp:(CACurrentMediaTime()*1000)];
    
 
    
    CVPixelBufferRelease(newPixcelBuffer);
}

@end
