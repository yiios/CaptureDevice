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
            signed short low1 = 0, low2 = 0;
            signed int newData = 0;
            int const MAX = 32767;
            int const MIN = -32768;
            
            for (int j = 0; j < model.videoData.length; j++) {
                low1 = totalModelBuf[j];
                if (i < encodeCount && !isInReceiver) {
                    low2 = p[j] * 0.2;
                    newData = (short)(low1 + low2);
                } else {
                    newData = low1;
                }
                if (newData > MAX)
                {
                    newData = MAX;
                }
                if (newData < MIN)
                {
                    newData = MIN;
                }
                totalModelBuf[j] = newData;
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
                model.timeStamp = (CACurrentMediaTime()*1000);
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
