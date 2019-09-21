//
//  MixAudioManager.m
//  ScreenCapture
//
//  Created by minzhe on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "MixAudioManager.h"
#import <AVFoundation/AVFoundation.h>

const NSInteger kLength = 2048;

@interface MixAudioManager ()
{
    char *leftBuf;
    NSInteger leftLength;
}

@property (nonatomic, strong) NSMutableArray *micModelArray;

@end

@implementation MixAudioManager


- (instancetype)init {
    if (self = [super init]) {
        [self configManager];
    }
    return self;
}

- (void)configManager {
    _micModelArray = [NSMutableArray array];
    if (!leftBuf) {
        leftBuf = malloc(kLength);
    }
}

- (void)sendMicBufferList:(NSData *)audioData timeStamp:(uint64_t)timeStamp {
    MixAudioModel *model = [[MixAudioModel alloc] init];
    model.videoData = audioData;
    model.timeStamp = timeStamp;
    [_micModelArray addObject:model];
}

- (void)sendAppBufferList:(NSData *)audioData timeStamp:(uint64_t)timeStamp {
    NSInteger totalSize = audioData.length;
    NSInteger encodeCount = totalSize/kLength;
    char *totalBuf = malloc(totalSize);
    char *p = totalBuf;
    memcpy(totalBuf, audioData.bytes, audioData.length);
    
    if (_micModelArray.count > 0) {
        BOOL isInReceiver = [self isInReceiverPluggedIn];
        for (NSInteger i = 0;i < _micModelArray.count;i++) {
            MixAudioModel *model = _micModelArray[i];
            
            char *totalModelBuf = malloc(model.videoData.length);
            memcpy(totalModelBuf, model.videoData.bytes, model.videoData.length);
            int const MAX = 32767;
            int const MIN = -32768;
            short app = 0, mic = 0;
            for (int j = 0; j < model.videoData.length; j+=2) {
                if (i < encodeCount && !isInReceiver) {
//                if (i < encodeCount) {

                    mic = 0xFF00 & (totalModelBuf[j] << 8);
                    mic += (totalModelBuf[j+1] & 0x00FF);
                    app = 0xFF00 & (p[j] << 8);
                    app += (p[j+1] & 0x00FF);
                    app = app*0.2 + mic;
                    if (app > MAX)
                    {
                        app = MAX;
                    }
                    if (app < MIN)
                    {
                        app = MIN;
                    }
                    
                    totalModelBuf[j] = ((short)((app&0xFF00)>>8));
                    totalModelBuf[j+1] = ((short)app&0x00FF);
                } else {
                    totalModelBuf[j] = totalModelBuf[j];
                    totalModelBuf[j+1] = totalModelBuf[j+1];
                }
                
            }
            model.videoData = [[NSData alloc] initWithBytes:totalModelBuf length:model.videoData.length];
            free(totalModelBuf);
            if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
                [self.delegate mixDidOutputModel:model];
            }
            if (i < encodeCount) {
                p += kLength;
            }
        }
    } else {
        for(NSInteger index = 0;index < encodeCount;index++){
            char *totalModelBuf = malloc(kLength);
            memcpy(totalModelBuf, p, kLength);
            if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
                MixAudioModel *model = [[MixAudioModel alloc] init];
                model.videoData = [[NSData alloc] initWithBytes:totalModelBuf length:kLength];
                model.timeStamp = (CACurrentMediaTime()*1000) - 500 + 500/encodeCount*index;
                [self.delegate mixDidOutputModel:model];
            }
            free(totalModelBuf);
            p += kLength;
        }
    }
    free(totalBuf);
    [_micModelArray removeAllObjects];
}

- (BOOL)isInReceiverPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {

        if ([[desc portType] isEqualToString:AVAudioSessionPortBuiltInReceiver] || [[desc portType] isEqualToString:AVAudioSessionPortBuiltInSpeaker])
            return YES;
    }
    return NO;
}

@end
