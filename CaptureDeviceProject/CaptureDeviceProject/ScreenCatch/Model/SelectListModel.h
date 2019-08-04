//
//  SelectListModel.h
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectListModel : NSObject

@property (nonatomic, assign) NSInteger valueNumber;
@property (nonatomic, copy) NSString *titleString;

- (instancetype)initWithValueNumber:(NSInteger)valueNumber titleString:(NSString *)titleString;

@end

NS_ASSUME_NONNULL_END
