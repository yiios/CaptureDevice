//
//  SelectListModel.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "SelectListModel.h"

@implementation SelectListModel

- (instancetype)initWithValueNumber:(NSInteger)valueNumber titleString:(NSString *)titleString {
    if (self = [super init]) {
        _valueNumber = valueNumber;
        _titleString = titleString;
    }
    return self;
}
@end
