//
//  MixAudioManager.h
//  ScreenCapture
//
//  Created by minzhe on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface MixAudioManager : NSObject

- (instancetype)initWithInputFormat:(AudioStreamBasicDescription)inputFormat;

-(void)stopAUGraph;
-(void)startAUGraph;

- (void)pushAppData:(NSData*)audioData;
- (void)pushMicData:(NSData*)audioData;

@end

NS_ASSUME_NONNULL_END
