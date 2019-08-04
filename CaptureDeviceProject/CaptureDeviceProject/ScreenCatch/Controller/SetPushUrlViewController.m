//
//  SetPushUrlViewController.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "SetPushUrlViewController.h"

@interface SetPushUrlViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *pastBtn;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@end

@implementation SetPushUrlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"推流地址";
    UIBarButtonItem *saveBtn = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveBtnClicked)];
    [saveBtn setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14],NSFontAttributeName, nil] forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:saveBtn];
    [self initView];
}

- (void)saveBtnClicked {
    if (![self.textView.text hasPrefix:@"rtmp://"]) {
        [self.view showHint:@"请输入正确的rtmp推流地址"];
        return;
    }
    if (self.savePushUrlBlock) {
        self.savePushUrlBlock(self.textView.text);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initView {
    self.textView.delegate = self;
    self.textView.layer.cornerRadius = 6;
    self.textView.layer.masksToBounds = YES;
    self.pastBtn.layer.cornerRadius = 6;
    self.pastBtn.layer.masksToBounds = YES;
    if (self.urlStr.length > 0) {
        self.textView.text = self.urlStr;
        self.placeholderLabel.hidden = YES;
    }
    
}

- (IBAction)pastBtnAct:(id)sender {
    if ([UIPasteboard generalPasteboard].string.length > 0) {
        self.textView.text = [UIPasteboard generalPasteboard].string;
        self.placeholderLabel.hidden = YES;
    }
}

#pragma mark -- UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * new_text_str = [textView.text stringByReplacingCharactersInRange:range withString:text];//变化后的字符串
    self.placeholderLabel.hidden = new_text_str.length != 0;
    return YES;
}

@end
