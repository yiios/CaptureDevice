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

@property (nonatomic, strong) LFLiveVideoConfiguration *videoConfiguration;

@property (nonatomic, assign) BOOL canUpload;

//@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;



@end

@implementation SampleHandler

- (LFLiveStreamInfo *)streamInfo {
    if (!_streamInfo) {
        _streamInfo = [[LFLiveStreamInfo alloc] init];
        _streamInfo.url = @"rtmp://push-rtmp-l6.douyincdn.com/third/stream-6719745786529286916?did=43547290386&k=b93356042023011d&t=1565172452&uid=101863542832";
        
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
        _videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:[LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High3 outputImageOrientation:UIInterfaceOrientationLandscapeRight]];
        [_videoEncoder setDelegate:self];
    }
    
  
    return _videoEncoder;
}


- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
//    NSString *urlStr = @"http://web.juhe.cn:8080/constellation/getAll";
//    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//
//    //创建request
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
//    request.HTTPMethod = @"POST";
//    request.HTTPBody = [@"key=12bb68a2f0a5b97bed27d660ef23229f&consName=金牛座&type=today" dataUsingEncoding:NSUTF8StringEncoding];
//
//    //创建NSURLSession
//    NSURLSession *session = [NSURLSession sharedSession];
//
//    //创建任务
//    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSLog(@"****%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//    }];
//
//    //开始任务
//    [task resume];
    
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.gunmm.CaptureDeviceProject"];
    
    NSLog(@"------url: %@ -------", [userDefaults valueForKey:@"rtmpPushUrl"]);

    NSLog(@"------Start-------");
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithScreenCapure];
    
    [self.socket start];
    
    
    self.output = [[GPUImageFilter alloc] init];
//    self.filter = [[LFGPUImageEmptyFilter alloc] init];
//    [self.videoCamera addTarget:self.filter];
//    [self.filter addTarget:self.output];
//    [self.output addTarget:self.gpuImageView];
//
//    //< 输出数据
//    __weak typeof(self) _self = self;
    [self.output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        NSLog(@"-------");
//        [_self processVideo:output];
    }];

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
            
            [self.videoCamera processVideoSampleBuffer:sampleBuffer];
            
//            if (self.canUpload) {
//                CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//                CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//                sourceImage = [sourceImage imageByApplyingOrientation:kCGImagePropertyOrientationRight];
//
//                CGFloat outputWidth  = 1280;
//                CGFloat outputHeight = 720;
//                CGFloat inputWidth = sourceImage.extent.size.width;
//                CGFloat inputHeight = sourceImage.extent.size.height;
//                CGAffineTransform tranfrom = CGAffineTransformMakeScale(outputWidth/inputWidth, outputHeight/inputHeight);
//                CIImage *outputImage = [sourceImage imageByApplyingTransform:tranfrom];
//
////                //这句话最主要
//                CIContext *context = [CIContext contextWithOptions:nil];
////                CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
//
//                CVPixelBufferRef outputPixelBuffer = NULL;
//                if (!outputPixelBuffer) {
//                    //推流
//                    NSDictionary* pixelBufferOptions = @{
//                                                         (NSString*) kCVPixelBufferWidthKey : @(outputWidth),
//                                                         (NSString*) kCVPixelBufferHeightKey : @(outputHeight),
//                                                         (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
//                                                         (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}
//                                                         };
//                    CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault, outputWidth, outputHeight, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)pixelBufferOptions, &outputPixelBuffer);
//
//                    if (ret!= noErr) {
//                        NSLog(@"创建streamer buffer失败");
//                        outputPixelBuffer = nil;
//                    }
//                }
//                [context render:outputImage toCVPixelBuffer:outputPixelBuffer bounds:outputImage.extent colorSpace:CGColorSpaceCreateDeviceRGB()];
//                [self.videoEncoder encodeVideoData:outputPixelBuffer timeStamp:(CACurrentMediaTime()*1000)];
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
    NSLog(@"------");
    //上传 时间戳对齐
//    if (self.uploading){
//    [self pushSendBuffer:frame];
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
    //    if (status == LFLiveStart) {
    //        if (!self.uploading) {
    //            self.AVAlignment = NO;
    //            self.hasCaptureAudio = NO;
    //            self.hasKeyFrameVideo = NO;
    //            self.relativeTimestamps = 0;
    //            self.uploading = YES;
    //        }
    //    } else if(status == LFLiveStop || status == LFLiveError){
    //        self.uploading = NO;
    //    }
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        self.state = status;
    //        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
    //            [self.delegate liveSession:self liveStateDidChange:status];
    //        }
    //    });
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

@end
