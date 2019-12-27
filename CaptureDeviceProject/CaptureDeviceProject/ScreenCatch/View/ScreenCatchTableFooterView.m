//
//  ScreenCatchTableFooterView.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "ScreenCatchTableFooterView.h"
#import "PayManager.h"

CGFloat const ScreenCatchTableFooterViewHeight = 94;

@interface ScreenCatchTableFooterView ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation ScreenCatchTableFooterView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.prView.preferredExtension = @"gunmm.CaptureDeviceProject.ScreenCapture";
    self.clipsToBounds = YES;
    self.bgView.layer.cornerRadius = 6;
    self.bgView.layer.masksToBounds = YES;
}

+ (ScreenCatchTableFooterView *)loadScreenCatchTableFooterView {
    ScreenCatchTableFooterView *screenCatchTableFooterView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] lastObject];
    return screenCatchTableFooterView;
}

- (void)setShowBtn:(BOOL)showBtn {
    _showBtn = showBtn;
    if (_showBtn) {
        self.titleLabel.text = @"开始           推流";
        self.titleLabel.backgroundColor = mainColor;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.prView.hidden = NO;
       
    } else {
        self.titleLabel.text = @"未设置地址";
        self.titleLabel.backgroundColor = [UIColor grayColor];
        self.titleLabel.textColor = bgColor;
        self.prView.hidden = YES;
    }
}

- (IBAction)failed:(id)sender {
//    if (self.failedBtnActBlock) {
//        self.failedBtnActBlock();
//    }
    
    [[PayManager manager] getRequestAppleProduct];
}


@end
