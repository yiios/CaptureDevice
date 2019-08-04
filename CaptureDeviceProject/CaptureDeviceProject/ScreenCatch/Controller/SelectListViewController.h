//
//  SelectListViewController.h
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "BaseViewController.h"
#import "SelectListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SelectListViewController : BaseViewController

@property (nonatomic, strong) NSMutableArray <SelectListModel *> *dataList;
@property (nonatomic, strong) SelectListModel *currentSelectCellModel;
@property (nonatomic, copy) void(^selectListCellBlock)(SelectListModel *selectCellModel);

@end

NS_ASSUME_NONNULL_END
