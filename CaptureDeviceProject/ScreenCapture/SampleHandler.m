//
//  SampleHandler.m
//  ScreenCapture
//
//  Created by minzhe on 2019/7/31.
//  Copyright © 2019 minzhe. All rights reserved.
//


#import "SampleHandler.h"
#import <LFLiveKit/LFLiveKit.h>
#import "XDXAduioEncoder.h"

//输出音频的采样率(也是session设置的采样率)，
const double kGraphSampleRate = 44100.0;
//每次回调提供多长时间的数据,结合采样率 0.005 = x*1/44100, x = 220.5, 因为回调函数中的inNumberFrames是2的幂，所以x应该是256
const double kSessionBufDuration    = 0.005;

@interface SampleHandler () <LFStreamSocketDelegate, LFVideoEncodingDelegate, LFAudioEncodingDelegate>
{
    AUGraph        _mGraph;
    AudioUnit      _mMixer;
    AudioUnit      _mOutput;
    AudioStreamBasicDescription _mAudioFormat; //输入到文件和录音和混音后的pcm数据的格式
}

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) id<LFStreamSocket> socket;
@property (nonatomic, strong) LFLiveStreamInfo *streamInfo;

@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;
/// 音频编码
@property (nonatomic, strong) id<LFAudioEncoding> audioEncoder;

@property (nonatomic, strong) XDXAduioEncoder *audioEncoder2;


/// 音频配置
@property (nonatomic, strong) LFLiveAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) LFLiveVideoConfiguration *videoConfiguration;



@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, assign) uint64_t relativeTimestamps;

@property (nonatomic, assign) BOOL canUpload;

@property (nonatomic, strong) dispatch_queue_t rotateQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) LFVideoFrame *lastRecordFrame;
@property (nonatomic, assign) uint64_t lastTimeSpace;
@property (nonatomic, strong) CIImage *lastCIImage;
@property (nonatomic, assign) size_t lastWidth;
@property (nonatomic, assign) size_t lastHeight;
@property (nonatomic, assign) uint64_t lastTime;

@property (nonatomic, assign) UIInterfaceOrientation encoderOrientation;
@property (nonatomic, assign) CGImagePropertyOrientation rotateOrientation;

@property (nonatomic, assign) CMSampleBufferRef applicationBuffer;
@property (nonatomic, assign) CMSampleBufferRef micBuffer;

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
        NSLog(@"self.videoConfiguration d方向：%ld", (long)self.videoConfiguration.outputImageOrientation);
    }
    return _videoEncoder;
}

- (LFLiveVideoConfiguration *)videoConfiguration {
    if (!_videoConfiguration) {
        _videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High3 outputImageOrientation:self.encoderOrientation];
    }
    return _videoConfiguration;

}

- (id<LFAudioEncoding>)audioEncoder {
    if (!_audioEncoder) {
        _audioEncoder = [[LFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:self.audioConfiguration];
        [_audioEncoder setDelegate:self];
    }
    return _audioEncoder;
}

- (LFLiveAudioConfiguration *)audioConfiguration {
    if (!_audioConfiguration) {
        _audioConfiguration = [LFLiveAudioConfiguration defaultConfiguration];
    }
    return _audioConfiguration;
}

- (UIInterfaceOrientation)encoderOrientation {
    NSInteger screenOrientationValue = [[_userDefaults objectForKey:@"screenOrientationValue"] integerValue];
    UIInterfaceOrientation orientationValue = UIInterfaceOrientationPortrait;
    switch (screenOrientationValue) {
        case 1:
            orientationValue = UIInterfaceOrientationLandscapeLeft;
            break;
        case 2:
            orientationValue = UIInterfaceOrientationLandscapeRight;
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
    _videoConfiguration = nil;
    _videoEncoder = nil;
    _streamInfo = nil;
    
    if (_socket) {
        [_socket stop];
        _socket = nil;
    }
    
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.gunmm.CaptureDeviceProject"];
    self.rotateQueue = dispatch_queue_create("rotateQueue", nil);
    self.audioQueue = dispatch_queue_create("audioQueue", nil);

    [self.socket start];
    _ciContext = [CIContext contextWithOptions:nil];
    
    __weak typeof(self) weakSelf = self;
    CADisplayLink *_link = [CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(checkFPS:)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
//    [self mixer];
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
//        {
//            CFRetain(sampleBuffer);
//            dispatch_async(self.audioQueue, ^{
//                //获取audioformat的描述信息
//                CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
//                //获取输入的asbd的信息
//                AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
//                [self.audioEncoder setCustomInputFormat:inAudioStreamBasicDescription];
//
//                AudioBufferList audioBufferList;
//                CMBlockBufferRef blockBuffer;
//                OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
//                if (status != noErr) {
//                    NSLog(@"从block中获取pcm数据失败");
//                    CFRelease(sampleBuffer);
//                    return;
//                } else {
//                    Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(CACurrentMediaTime()));
//                    int64_t pts = (int64_t)((currentTime - 100) * 1000);
//
//                    void    *bufferData = audioBufferList.mBuffers[0].mData;
//                    UInt32   bufferSize = audioBufferList.mBuffers[0].mDataByteSize;
//                    CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
//                    //获取输入的asbd的信息
//                    AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
//
//                    if (!self.audioEncoder2) {
//                        AudioStreamBasicDescription inputFormat = {0};
//
//                        inputFormat.mSampleRate = 44100;
//                        inputFormat.mFormatID = kAudioFormatLinearPCM;
//                        inputFormat.mFormatFlags = inAudioStreamBasicDescription.mFormatFlags;
//                        inputFormat.mChannelsPerFrame = 1;
//                        inputFormat.mFramesPerPacket = 1;
//                        inputFormat.mBitsPerChannel = 16;
//                        inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
//                        inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
//                        self.audioEncoder2 = [[XDXAduioEncoder alloc] initWithSourceFormat:inputFormat
//                                                                              destFormatID:kAudioFormatMPEG4AAC
//                                                                                sampleRate:44100
//                                                                       isUseHardwareEncode:YES];
//                    }
//                    [self.audioEncoder2 encodeAudioWithSourceBuffer:bufferData sourceBufferSize:bufferSize pts:pts completeHandler:^(LFAudioFrame * _Nonnull frame) {
//                        NSLog(@"audioInfo -- %lu", (unsigned long)frame.audioInfo.length);
//                        NSLog(@"data -- %lu", (unsigned long)frame.data.length);
//                        NSLog(@"header -- %lu", (unsigned long)frame.header.length);
//
//                        if(self.relativeTimestamps == 0){
//                            self.relativeTimestamps = frame.timestamp;
//                        }
//                        frame.timestamp = [self uploadTimestamp:frame.timestamp];
//                        [self.socket sendFrame:frame];
//                    }];
//
//
//                    //                    for( int y = 0; y < audioBufferList.mNumberBuffers; y++) {
//                    //                        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
//                    //                        void* audio = audioBuffer.mData;//这里获取
//                    //                        [self.audioEncoder encodeAudioData:[NSData dataWithBytes:audio length:audioBuffer.mDataByteSize] timeStamp:(CACurrentMediaTime()*1000)];
//                    //
//                    //                    }
//                }
//                CFRelease(sampleBuffer);
//            });
//            break;
//        }
//        {
//            CFRetain(sampleBuffer);
//            dispatch_async(self.audioQueue, ^{
//                //获取audioformat的描述信息
//                CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
//                //获取输入的asbd的信息
//                AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
//                [self.audioEncoder setCustomInputFormat:inAudioStreamBasicDescription];
//
//                AudioBufferList audioBufferList;
//                CMBlockBufferRef blockBuffer;
//                OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
//                if (status != noErr) {
//                    NSLog(@"从block中获取pcm数据失败");
//                    CFRelease(sampleBuffer);
//                    return;
//                } else {
//                    for( int y = 0; y < audioBufferList.mNumberBuffers; y++) {
//                        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
//                        void* audio = audioBuffer.mData;//这里获取
//                        [self.audioEncoder encodeAudioData:[NSData dataWithBytes:audio length:audioBuffer.mDataByteSize] timeStamp:(CACurrentMediaTime()*1000)];
//
////                        [self.audioEncoder2 encodeAudioWithSourceBuffer:audioBuffer.mData sourceBufferSize:audioBuffer.mDataByteSize pts:(CACurrentMediaTime()*1000) completeHandler:^(LFAudioFrame * _Nonnull frame) {
////                            NSLog(@"audioInfo -- %lu", (unsigned long)frame.audioInfo.length);
////                            NSLog(@"data -- %lu", (unsigned long)frame.data.length);
////                            NSLog(@"header -- %lu", (unsigned long)frame.header.length);
////
////
////                            if(self.relativeTimestamps == 0){
////                                self.relativeTimestamps = frame.timestamp;
////                            }
////                            frame.timestamp = [self uploadTimestamp:frame.timestamp];
////                            [self.socket sendFrame:frame];
////                        }];
//                    }
//                }
//                CFRelease(sampleBuffer);
//            });
//            break;
//        }
        {
//            NSLog(@"----------s音频来了");
//            CFRetain(sampleBuffer);
//            dispatch_async(self.audioQueue, ^{
//                //从samplebuffer中获取blockbuffer
//                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//                size_t pcmLength = 0;
//                char *pcmData = NULL;
//                //获取blockbuffer中的pcm数据的指针和长度
//                OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &pcmLength, &pcmData);
//                if (status != noErr) {
//                    NSLog(@"从block中获取pcm数据失败");
//                    CFRelease(sampleBuffer);
//                    return;
//                } else {
//                    CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
//                    //获取输入的asbd的信息
//                    AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
//                    [self.audioEncoder setCustomInputFormat:inAudioStreamBasicDescription];
//                    //在堆区分配内存用来保存编码后的aac数据
//                    NSData *data = [[NSData alloc] initWithBytes:pcmData length:pcmLength];
////                    [self.audioEncoder encodeAudioData:data timeStamp:(CACurrentMediaTime()*1000)];
//                }
//                CFRelease(sampleBuffer);
//            });
//
            break;
        }
          
        case RPSampleBufferTypeAudioMic:
        {
            CFRetain(sampleBuffer);
            dispatch_async(self.audioQueue, ^{
                //获取audioformat的描述信息
                CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
                //获取输入的asbd的信息
                AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
                [self.audioEncoder setCustomInputFormat:inAudioStreamBasicDescription];

                AudioBufferList audioBufferList;
                CMBlockBufferRef blockBuffer;
                OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
                if (status != noErr) {
                    NSLog(@"从block中获取pcm数据失败");
                    CFRelease(sampleBuffer);
                    return;
                } else {
                    Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(CACurrentMediaTime()));
                    int64_t pts = (int64_t)((currentTime - 100) * 1000);

                    void    *bufferData = audioBufferList.mBuffers[0].mData;
                    UInt32   bufferSize = audioBufferList.mBuffers[0].mDataByteSize;
                    CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
                    //获取输入的asbd的信息
                    AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));

                    if (!self.audioEncoder2) {
                        AudioStreamBasicDescription inputFormat = {0};

                        inputFormat.mSampleRate = 44100;
                        inputFormat.mFormatID = kAudioFormatLinearPCM;
                        inputFormat.mFormatFlags = inAudioStreamBasicDescription.mFormatFlags;
                        inputFormat.mChannelsPerFrame = 1;
                        inputFormat.mFramesPerPacket = 1;
                        inputFormat.mBitsPerChannel = 16;
                        inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
                        inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
                        self.audioEncoder2 = [[XDXAduioEncoder alloc] initWithSourceFormat:inputFormat
                                                                              destFormatID:kAudioFormatMPEG4AAC
                                                                                sampleRate:44100
                                                                       isUseHardwareEncode:YES];
                    }
                    [self.audioEncoder2 encodeAudioWithSourceBuffer:bufferData sourceBufferSize:bufferSize pts:pts completeHandler:^(LFAudioFrame * _Nonnull frame) {
                        NSLog(@"audioInfo -- %lu", (unsigned long)frame.audioInfo.length);
                        NSLog(@"data -- %lu", (unsigned long)frame.data.length);
                        NSLog(@"header -- %lu", (unsigned long)frame.header.length);

                        if(self.relativeTimestamps == 0){
                            self.relativeTimestamps = frame.timestamp;
                        }
                        frame.timestamp = [self uploadTimestamp:frame.timestamp];
                        [self.socket sendFrame:frame];
                    }];


//                    for( int y = 0; y < audioBufferList.mNumberBuffers; y++) {
//                        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
//                        void* audio = audioBuffer.mData;//这里获取
//                        [self.audioEncoder encodeAudioData:[NSData dataWithBytes:audio length:audioBuffer.mDataByteSize] timeStamp:(CACurrentMediaTime()*1000)];
//
//                    }
                }
                CFRelease(sampleBuffer);
            });
            break;
        }
            
            
            
//        {
//            NSLog(@"----------mic音频来了");
//            if (self.canUpload) {
//                CFRetain(sampleBuffer);
//                dispatch_async(self.audioQueue, ^{
//                    //从samplebuffer中获取blockbuffer
//                    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//                    size_t pcmLength = 0;
//                    char *pcmData = NULL;
//                    //获取blockbuffer中的pcm数据的指针和长度
//                    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &pcmLength, &pcmData);
//                    if (status != noErr) {
//                        NSLog(@"从block中获取pcm数据失败");
//                        CFRelease(sampleBuffer);
//                        return;
//                    } else {
//                        CMAudioFormatDescriptionRef audioFormatDes =  (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
//                        //获取输入的asbd的信息
//                        AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDes));
//                        [self.audioEncoder setCustomInputFormat:inAudioStreamBasicDescription];
//                        //在堆区分配内存用来保存编码后的aac数据
//                        NSData *data = [[NSData alloc] initWithBytes:pcmData length:pcmLength];
//                        [self.audioEncoder encodeAudioData:data timeStamp:(CACurrentMediaTime()*1000)];
//                    }
//                    CFRelease(sampleBuffer);
//                });
//            }
//            break;
//        }
            
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

- (uint64_t)uploadTimestampMic:(uint64_t)captureTimestamp{
    dispatch_semaphore_wait(self.lockMic, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.micRelativeTimestamps;
    dispatch_semaphore_signal(self.lockMic);
    return currentts;
}

- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (dispatch_semaphore_t)lockMic{
    if(!_lockMic){
        _lockMic = dispatch_semaphore_create(1);
    }
    return _lockMic;
}

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame {
    if (self.canUpload){
        [self pushSendBuffer:frame];
        self.lastRecordFrame = frame;
    }
}

- (void)audioEncoder:(nullable id<LFAudioEncoding>)encoder audioFrame:(nullable LFAudioFrame *)frame {
//    NSLog(@"audioInfo -- %lu", (unsigned long)frame.audioInfo.length);
//    NSLog(@"data -- %lu", (unsigned long)frame.data.length);
//    NSLog(@"header -- %lu", (unsigned long)frame.header.length);

//    NSLog(@"--  %@", frame.audioInfo);
    if (self.canUpload){
        NSLog(@"*********************");
        [self pushSendBuffer:frame];
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

- (void)pushMicSendBuffer:(LFFrame*)frame{
    if(self.micRelativeTimestamps == 0){
        self.micRelativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestampMic:frame.timestamp];
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
    
    if (self.rotateOrientation == kCGImagePropertyOrientationUp) {
//        NSLog(@"不旋转----%zu,   %zu", width, height);
        [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:(CACurrentMediaTime()*1000)];
    } else {
//        NSLog(@"旋转----%zu,   %zu", width, height);

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
    size_t width, height;
    if (self.rotateOrientation != kCGImagePropertyOrientationUp) {
        wImage = [lastCIImage imageByApplyingCGOrientation:self.rotateOrientation];
        width = self.lastHeight;
        height = self.lastWidth;
    } else {
        wImage = lastCIImage;
        width = self.lastWidth;
        height = self.lastHeight;
    }
    CIImage *newImage = [wImage imageByApplyingTransform:CGAffineTransformMakeScale(1, 1)];
    CVPixelBufferRef newPixcelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &newPixcelBuffer);
    [_ciContext render:newImage toCVPixelBuffer:newPixcelBuffer];
    [self.videoEncoder encodeVideoData:newPixcelBuffer timeStamp:(CACurrentMediaTime()*1000)];
    CVPixelBufferRelease(newPixcelBuffer);
}




#pragma mark --- 混音
void CheckError(OSStatus error,const char *operaton){
    if (error==noErr) {
        return;
    }
    char errorString[20]={};
    *(UInt32 *)(errorString+1)=CFSwapInt32HostToBig(error);
    if (isprint(errorString[1])&&isprint(errorString[2])&&isprint(errorString[3])&&isprint(errorString[4])) {
        errorString[0]=errorString[5]='\'';
        errorString[6]='\0';
    }else{
        sprintf(errorString, "%d",(int)error);
    }
    fprintf(stderr, "Error:%s (%s)\n",operaton,errorString);
    exit(1);
}


- (void)mixer {
    CheckError(NewAUGraph(&_mGraph), "cant new a graph");
    
    
    AUNode mixerNode;
    AUNode outputNode;
    
    AudioComponentDescription mixerACD;
    mixerACD.componentType      = kAudioUnitType_Mixer;
    mixerACD.componentSubType   = kAudioUnitSubType_MultiChannelMixer;
    mixerACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerACD.componentFlags = 0;
    mixerACD.componentFlagsMask = 0;
    
    AudioComponentDescription outputACD;
    outputACD.componentType      = kAudioUnitType_Output;
    outputACD.componentSubType   = kAudioUnitSubType_RemoteIO;
    outputACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputACD.componentFlags = 0;
    outputACD.componentFlagsMask = 0;
    
    CheckError(AUGraphAddNode(_mGraph, &mixerACD,
                              &mixerNode),
               "cant add node");
    CheckError(AUGraphAddNode(_mGraph, &outputACD,
                              &outputNode),
               "cant add node");
    
    CheckError(AUGraphConnectNodeInput(_mGraph, mixerNode, 0, outputNode, 0),
               "connect mixer Node to output node error");
    
    CheckError(AUGraphOpen(_mGraph), "cant open the graph");
    
    CheckError(AUGraphNodeInfo(_mGraph, mixerNode,
                               NULL, &_mMixer),
               "generate mixer unit error");
    CheckError(AUGraphNodeInfo(_mGraph, outputNode, NULL, &_mOutput),
               "generate remote I/O unit error");
    
    UInt32 enable = 1;
    AudioUnitSetProperty(_mOutput,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         1,
                         &enable,
                         sizeof(enable));
    
    
    _mAudioFormat.mSampleRate         = kGraphSampleRate;//采样率
    _mAudioFormat.mFormatID           = kAudioFormatLinearPCM;//PCM采样
    _mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _mAudioFormat.mFramesPerPacket    = 1;//每个数据包多少帧
    _mAudioFormat.mChannelsPerFrame   = 1;//1单声道，2立体声
    _mAudioFormat.mBitsPerChannel     = 16;//语音每采样点占用位数
    _mAudioFormat.mBytesPerFrame      = _mAudioFormat.mBitsPerChannel*_mAudioFormat.mChannelsPerFrame/8;//每帧的bytes数
    _mAudioFormat.mBytesPerPacket     = _mAudioFormat.mBytesPerFrame*_mAudioFormat.mFramesPerPacket;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
    _mAudioFormat.mReserved           = 0;
    
    
    CheckError(AudioUnitSetProperty(_mOutput,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output, 1,
                                    &_mAudioFormat, sizeof(AudioStreamBasicDescription)),
               "couldn't set the remote I/O unit's input client format");
    
    
    
    AudioUnitSetProperty(_mMixer,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         0,
                         &_mAudioFormat, sizeof(AudioStreamBasicDescription));
    
    
    
//    CheckError(AudioUnitAddRenderNotify(_mMixer, playUnitInputCallback, (__bridge void *)self), "couldnt set notify");
    
    
    
    UInt32 numberOfMixBus = 3;
    
    //配置混音的路数，有多少个音频文件要混音
    CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,
                                    &numberOfMixBus, sizeof(numberOfMixBus)),
               "set mix elements error");
    
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    CheckError( AudioUnitSetProperty (_mMixer,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &maximumFramesPerSlice,
                                      sizeof (maximumFramesPerSlice)
                                      ), "cant set kAudioUnitProperty_MaximumFramesPerSlice");
    
    
    for (int i = 0; i < numberOfMixBus; i++) {
        // setup render callback struct
        AURenderCallbackStruct rcbs;
        rcbs.inputProc = &renderInput;
        //        rcbs.inputProcRefCon = _mSoundBufferP;
        rcbs.inputProcRefCon = (__bridge void *)(self);
        
        CheckError(AUGraphSetNodeInputCallback(_mGraph, mixerNode, i, &rcbs),
                   "set mixerNode callback error");
        
        if (i == numberOfMixBus - 1) {
            
            CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input, i,
                                            &_mAudioFormat, sizeof(AudioStreamBasicDescription)),
                       "cant set the input scope format for record");
            break;
        }
        
        AVAudioFormat *clientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                       sampleRate:kGraphSampleRate
                                                                         channels:1
                                                                      interleaved:NO];
        
        CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input, i,
                                        clientFormat.streamDescription, sizeof(AudioStreamBasicDescription)),
                   "cant set the input scope format on bus[i]");
        
    }
    
    
    
    
    
    double sample = kGraphSampleRate;
    CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_SampleRate,
                                    kAudioUnitScope_Output, 0,&sample , sizeof(sample)),
               "cant the mixer unit output sample");
    //未设置io unit kAudioUnitScope_Output 的element 1的输出AudioComponentDescription
    
    
    CheckError(AUGraphInitialize(_mGraph), "cant initial graph");
}


static OSStatus renderInput(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber, UInt32 inNumberFrames,
                            AudioBufferList *ioData)
{
    SampleHandler *THIS=(__bridge SampleHandler*)inRefCon;
    if (inBusNumber == 2) {
        
        OSStatus status = AudioUnitRender(THIS->_mOutput,
                                          ioActionFlags,
                                          inTimeStamp,
                                          1,
                                          inNumberFrames,
                                          ioData);
        
        return status;
    }
    SInt16 *outL = (SInt16 *)ioData->mBuffers[0].mData; // output audio buffer for L channel

    if (inBusNumber == 0) {
        CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(THIS.applicationBuffer);
        CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(THIS.applicationBuffer);
        AudioBufferList audioBufferList;
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(THIS.applicationBuffer,
                                                                NULL,
                                                                &audioBufferList,
                                                                sizeof(audioBufferList),
                                                                NULL,
                                                                NULL,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &buffer
                                                                );
        
        for (UInt32 i = 0; i < inNumberFrames; ++i) {
            if (i < numSamplesInBuffer) {
                SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[i].mData;
                outL[i] = *samples;
            }
        }
        NSLog(@"applicationBuffer");
       
        
    } else if (inBusNumber == 1) {
        CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(THIS.micBuffer);
        CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(THIS.micBuffer);
        AudioBufferList audioBufferList;
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(THIS.micBuffer,
                                                                NULL,
                                                                &audioBufferList,
                                                                sizeof(audioBufferList),
                                                                NULL,
                                                                NULL,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &buffer
                                                                );
        
        for (UInt32 i = 0; i < inNumberFrames; ++i) {
            if (i < numSamplesInBuffer) {
                SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[i].mData;
                outL[i] = *samples;
            }
        }
    }
    
    return noErr;
    
    
    
//    UInt32 sample = sndbuf[inBusNumber].sampleNum;      // frame number to start from
//    UInt32 bufSamples = sndbuf[inBusNumber].numFrames;  // total number of frames in the sound buffer
//    Float32 *leftData = sndbuf[inBusNumber].leftData; // audio data buffer
//    Float32 *rightData = nullptr;
//
//    Float32 *outL = (Float32 *)ioData->mBuffers[0].mData; // output audio buffer for L channel
////    Float32 *outR = nullptr;
////    if (sndbuf[inBusNumber].channelCount == 2) {
////        outR = (Float32 *)ioData->mBuffers[1].mData; //out audio buffer for R channel;
////        rightData = sndbuf[inBusNumber].rightData;
////    }
////
//    for (UInt32 i = 0; i < inNumberFrames; ++i) {
//        outL[i] = leftData[sample];
////        if (sndbuf[inBusNumber].channelCount == 2) {
////            outR[i] = rightData[sample];
////        }
//        sample++;
//
//        if (sample > bufSamples) {
//            // start over from the beginning of the data, our audio simply loops
//            printf("looping data for bus %d after %ld source frames rendered\n", (unsigned int)inBusNumber, (long)sample-1);
//            sample = 0;
//        }
//    }
//
//    sndbuf[inBusNumber].sampleNum = sample; // keep track of where we are in the source data buffer
//
//    return noErr;
//
//
//    //if the consumer wants to do something with the audio samples before writing, let him.
//    if (self.audioProcessingCallback) {
//        //need to introspect into the opaque CMBlockBuffer structure to find its raw sample buffers.
//        CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(audioBuffer);
//        CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(audioBuffer);
//        AudioBufferList audioBufferList;
//
//        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioBuffer,
//                                                                NULL,
//                                                                &audioBufferList,
//                                                                sizeof(audioBufferList),
//                                                                NULL,
//                                                                NULL,
//                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
//                                                                &buffer
//                                                                );
//        //passing a live pointer to the audio buffers, try to process them in-place or we might have syncing issues.
//        for (int bufferCount=0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
//            SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
//            self.audioProcessingCallback(&samples, numSamplesInBuffer);
//        }
//    }
}

static OSStatus playUnitInputCallback(void *inRefCon,
                                      
                                      AudioUnitRenderActionFlags *ioActionFlags,
                                      const AudioTimeStamp *inTimeStamp,
                                      UInt32 inBusNumber,
                                      UInt32 inNumberFrames,
                                      AudioBufferList *ioData) {
    
    
    //使用flag判断数据渲染前后，是渲染后状态则有数据可取
//    if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender){
//        MixerVoiceHandle *THIS=(__bridge MixerVoiceHandle*)inRefCon;
//        @synchronized (THIS) {
//            if (THIS->_recordMixPCM) {
//                CheckError(ExtAudioFileWrite(THIS->_fp,inNumberFrames, ioData),
//                           "cant write audio data to file") ;
//            }
//        }
//    }
    
    
    return noErr;
}


@end
