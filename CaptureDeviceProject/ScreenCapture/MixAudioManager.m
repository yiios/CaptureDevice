//
//  MixAudioManager.m
//  ScreenCapture
//
//  Created by minzhe on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "MixAudioManager.h"

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

- (void)sendMicBufferList:(AudioBuffer)buffer timeStamp:(uint64_t)timeStamp {
    MixAudioModel *model = [[MixAudioModel alloc] init];
    model.buffer = buffer;
    model.timeStamp = timeStamp;
//    if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
//        [self.delegate mixDidOutputModel:model];
//    }
    [_micModelArray addObject:model];
}

- (void)sendAppBufferList:(NSData *)audioData {
//    for (MixAudioModel *model in _micModelArray) {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
//                    [self.delegate mixDidOutputModel:model];
//                }
//    }
    
    if(leftLength + audioData.length >= kLength){
        ///<  发送
        NSInteger totalSize = leftLength + audioData.length;

        NSInteger encodeCount = totalSize/kLength;
        char *totalBuf = malloc(totalSize);
        char *p = totalBuf;

        memset(totalBuf, (int)totalSize, 0);
        memcpy(totalBuf, leftBuf, leftLength);
        memcpy(totalBuf + leftLength, audioData.bytes, audioData.length);

        for(NSInteger index = 0;index < encodeCount;index++){
            [self addBuffer:p index:index];
            p += kLength;
        }

        leftLength = totalSize%kLength;
        memset(leftBuf, 0, kLength);
        memcpy(leftBuf, totalBuf + (totalSize -leftLength), leftLength);
        free(totalBuf);
        [_micModelArray removeAllObjects];

    }else{
        ///< 积累
        memcpy(leftBuf+leftLength, audioData.bytes, audioData.length);
        leftLength = leftLength + audioData.length;
    }

}

- (void)addBuffer:(char*)buf index:(NSInteger)index {
    if (_micModelArray.count > index) {
        AudioBuffer inBuffer;
        inBuffer.mNumberChannels = 1;
        inBuffer.mData = buf;
        inBuffer.mDataByteSize = kLength;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = inBuffer;
        
        MixAudioModel *model = _micModelArray[index];
        AudioBuffer buffer = model.buffer;
        for (int i = 0; i < buffer.mDataByteSize; i++)
        {
            ((Byte *)buffer.mData)[i] = ((Byte *)buffer.mData)[i] + ((Byte *)inBuffer.mData)[i];
        }
        
        model.buffer = buffer;
        NSLog(@"%ld", index);
        
        MixAudioModel *model2 = [[MixAudioModel alloc] init];
        model2.buffer = inBuffer;
        model2.timeStamp = model.timeStamp;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
            [self.delegate mixDidOutputModel:model2];
        }
    }
}


@end
