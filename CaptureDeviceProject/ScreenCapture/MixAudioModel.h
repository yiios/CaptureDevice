//
//  MixAudioModel.h
//  ScreenCapture
//
//  Created by gunmm on 2019/8/28.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface MixAudioModel : NSObject

@property (nonatomic, strong) NSData *videoData;
@property (nonatomic, assign) uint64_t timeStamp;

@end

NS_ASSUME_NONNULL_END
