//
//  MixAudioManager.m
//  ScreenCapture
//
//  Created by minzhe on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "MixAudioManager.h"

@interface MixAudioManager ()
{
    AUGraph        _mGraph;
    AudioUnit      _mMixer;
    AudioUnit      _mOutput;
    char *appBuf;
    char *micBuf;
}

@property (nonatomic, assign) AudioStreamBasicDescription inputFormat;

@end

@implementation MixAudioManager

- (void)pushAppData:(NSData*)audioData {
    memcpy(appBuf, audioData.bytes, audioData.length);
    
    NSLog(@"");
}

- (void)pushMicData:(NSData*)audioData {
    memcpy(micBuf, audioData.bytes, audioData.length);
    NSLog(@"");

}

static OSStatus renderInput(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber, UInt32 inNumberFrames,
                            AudioBufferList *ioData)
{
//    NSLog(@"******** %u", (unsigned int)inNumberFrames);
//    MixerVoiceHandle *THIS=(__bridge MixerVoiceHandle*)inRefCon;
//    if (inBusNumber == 4) {
//
//        OSStatus status = AudioUnitRender(THIS->_mOutput,
//                                          ioActionFlags,
//                                          inTimeStamp,
//                                          1,
//                                          inNumberFrames,
//                                          ioData);
//
//        return status;
//    }
//    SoundBufferPtr sndbuf = (SoundBufferPtr)THIS->_mSoundBufferP;
//
//    UInt32 sample = sndbuf[inBusNumber].sampleNum;      // frame number to start from
//    UInt32 bufSamples = sndbuf[inBusNumber].numFrames;  // total number of frames in the sound buffer
//    Float32 *leftData = sndbuf[inBusNumber].leftData; // audio data buffer
//    Float32 *rightData = nullptr;
//
//    Float32 *outL = (Float32 *)ioData->mBuffers[0].mData; // output audio buffer for L channel
//    Float32 *outR = nullptr;
//    if (sndbuf[inBusNumber].channelCount == 2) {
//        outR = (Float32 *)ioData->mBuffers[1].mData; //out audio buffer for R channel;
//        rightData = sndbuf[inBusNumber].rightData;
//    }
//
//    for (UInt32 i = 0; i < inNumberFrames; ++i) {
//        if (sample == -10) {
//            NSLog(@"*********");
//            break;
//        }
//        outL[i] = leftData[sample];
//        if (sndbuf[inBusNumber].channelCount == 2) {
//            outR[i] = rightData[sample];
//        }
//        sample++;
//
//        if (sample > bufSamples) {
//            // start over from the beginning of the data, our audio simply loops
//            printf("looping data for bus %d after %ld source frames rendered\n", (unsigned int)inBusNumber, (long)sample-1);
//            sample = -10;
//        }
//    }
//
//    sndbuf[inBusNumber].sampleNum = sample; // keep track of where we are in the source data buffer
//
    return noErr;
}

static OSStatus playUnitInputCallback(void *inRefCon,
                                      
                                      AudioUnitRenderActionFlags *ioActionFlags,
                                      const AudioTimeStamp *inTimeStamp,
                                      UInt32 inBusNumber,
                                      UInt32 inNumberFrames,
                                      AudioBufferList *ioData) {
    
    
//    //使用flag判断数据渲染前后，是渲染后状态则有数据可取
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

- (instancetype)initWithInputFormat:(AudioStreamBasicDescription)inputFormat {
    if (self = [super init]) {
        _inputFormat = inputFormat;
        [self configManager];
    }
    return self;
}

- (void)configManager {
    
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
    
    CheckError(AudioUnitSetProperty(_mOutput,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output, 1,
                                    &_inputFormat, sizeof(AudioStreamBasicDescription)),
               "couldn't set the remote I/O unit's input client format");
    
    
    
    AudioUnitSetProperty(_mMixer,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         0,
                         &_inputFormat, sizeof(AudioStreamBasicDescription));
    
    
    
    CheckError(AudioUnitAddRenderNotify(_mMixer, playUnitInputCallback, (__bridge void *)self),
               "couldnt set notify");
    
    
    
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
        
        CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input, i,
                                        &_inputFormat, sizeof(AudioStreamBasicDescription)),
                   "cant set the input scope format for record");
    }
    
    
    
    
    
    double sample = _inputFormat.mSampleRate;
    CheckError(AudioUnitSetProperty(_mMixer, kAudioUnitProperty_SampleRate,
                                    kAudioUnitScope_Output, 0,&sample , sizeof(sample)),
               "cant the mixer unit output sample");
    //未设置io unit kAudioUnitScope_Output 的element 1的输出AudioComponentDescription
    
    
    CheckError(AUGraphInitialize(_mGraph), "cant initial graph");
}

-(void)stopAUGraph{
    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(_mGraph, &isRunning);
    if (result) { printf("AUGraphIsRunning result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    
    if (isRunning) {
        result = AUGraphStop(_mGraph);
        if (result) { printf("AUGraphStop result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
//        self.isPlaying = NO;
    }
}
-(void)startAUGraph{
    printf("PLAY\n");
    
    OSStatus result = AUGraphStart(_mGraph);
    if (result) { printf("AUGraphStart result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
//    self.isPlaying = YES;
    
}

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
@end
