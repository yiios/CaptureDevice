//
//  TestTimer.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/4.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "TestTimer.h"

@implementation TestTimer

- (void)beginTimer {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkFPS) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    //    [NSThread currentThread]
   
}

- (void)checkFPS {
    NSLog(@"=========");
}
@end
