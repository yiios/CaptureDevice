//
//  ScreenCatchTableFooterView.h
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScreenCatchTableFooterView : UIView

@property (weak, nonatomic) IBOutlet RPSystemBroadcastPickerView *prView;

@property (nonatomic, assign) BOOL showBtn;
@property (nonatomic, copy) void(^failedBtnActBlock)(void);


+ (ScreenCatchTableFooterView *)loadScreenCatchTableFooterView;

@end

NS_ASSUME_NONNULL_END
