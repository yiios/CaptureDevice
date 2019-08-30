//
//  MixAudioManager.m
//  ScreenCapture
//
//  Created by minzhe on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "MixAudioManager.h"
#import <AVFoundation/AVFoundation.h>

#define SIZE_AUDIO_FRAME (2)

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

- (void)addBuffer:(char *)buf index:(NSInteger)index {
    if (_micModelArray.count > index) {
        MixAudioModel *model = _micModelArray[index];
        char *totalModelBuf = malloc(kLength);
        memcpy(totalModelBuf, model.videoData.bytes, kLength);
        
        signed short low1 = 0, high1 = 0, data1 = 0, low2 = 0, high2 = 0, data2 = 0;
        signed long newData = 0;
        int const MAX = 32767;
        int const MIN = -32768;
        for (int i = 0; i < model.videoData.length; i+=2) {
            low1 = buf[i];
            high1 = buf[i+1];
            data1 = low1+(high1<<8);
            low2 = totalModelBuf[i];
            high2 = totalModelBuf[i+1];
            data2 = low2+(high2<<8);
            newData = data1 + data2*0.1;
            
            //边界值溢出处理
            double f=1;
            newData=(int)(newData*f);
            if (newData>MAX)
            {
                f=(double)MAX/(double)(newData);
                newData = MAX;
            }
            if (newData<MIN)
            {
                f=(double)MIN/(double)(newData);
                newData = MIN;
            }
            if (f<1)
            {
                f+=((double)1-f)/(double)32;
            }
            if (newData < MIN) {
                newData = data1;
            }else if (newData > MAX) {
                newData = data1;
            }
            signed long teData = 0;
            teData = newData&0xffff;
            totalModelBuf[i] = teData&0x00ff;
            totalModelBuf[i+1] = (teData&0xff00)>>8;
        }
    
        model.videoData = [[NSData alloc] initWithBytes:totalModelBuf length:kLength];
        
        free(totalModelBuf);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixDidOutputModel:)]) {
            [self.delegate mixDidOutputModel:model];
        }
    } else {
        MixAudioModel *model = [[MixAudioModel alloc] init];
        model.videoData = [[NSData alloc] initWithBytes:buf length:kLength];
        [self.delegate mixDidOutputModel:model];
    }
}


void Mix(char sourseFile[10][SIZE_AUDIO_FRAME],int number,char *objectFile)
{
    //归一化混音
    int const MAX=32767;
    int const MIN=-32768;
    
    double f=1;
    int output;
    int i = 0,j = 0;
    for (i=0;i<SIZE_AUDIO_FRAME/2;i++)
    {
        int temp=0;
        for (j=0;j<number;j++)
        {
            temp+=*(short*)sourseFile[j];
        }
        output=(int)(temp*f);
        if (output>MAX)
        {
            f=(double)MAX/(double)(output);
            output=MAX-100;
        }
        if (output<MIN)
        {
            f=(double)MIN/(double)(output);
            output=MIN+100;
        }
        if (f<1)
        {
            f+=((double)1-f)/(double)32;
        }
        *(short*)(objectFile+i*2)=(short)output;
    }
}

@end
