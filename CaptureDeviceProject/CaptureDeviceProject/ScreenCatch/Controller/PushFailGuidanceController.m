//
//  PushFailGuidanceController.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/24.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "PushFailGuidanceController.h"

@interface PushFailGuidanceController ()

@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end

@implementation PushFailGuidanceController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"推流指引";
    
    self.contentLabel.text = @"1. 确认rtmp推流地址正确\n\n2. 确认给与了软件网络、麦克风、相机、通知权限\n\n3. 确认打开了开始直播弹窗的麦克风（麦克风颜色为红色即为打开）\n\n4. 以上步骤皆已确认无误请联系开发者（qq：924744097）\n\n";
}



@end
