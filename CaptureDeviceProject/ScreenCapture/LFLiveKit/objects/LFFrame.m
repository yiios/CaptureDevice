//
//  LFFrame.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LFFrame.h"

@implementation LFFrame

- (NSComparisonResult)compareFrame:(LFFrame *)frame{
    
    NSComparisonResult result = [[NSNumber numberWithLongLong:self.timestamp] compare:[NSNumber numberWithLongLong:frame.timestamp]];//注意:基本数据类型要进行数据转换
    
    if (result == NSOrderedSame) {
        result = [[NSNumber numberWithLongLong:frame.timestamp] compare:[NSNumber numberWithLongLong:self.timestamp]];
    }
    return result;
}

@end
