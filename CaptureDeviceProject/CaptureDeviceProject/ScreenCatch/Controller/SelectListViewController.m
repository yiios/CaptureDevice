//
//  SelectListViewController.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/3.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "SelectListViewController.h"
#import "ClickJumpTableViewCell.h"

@interface SelectListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) ClickJumpTableViewCell *currentSelectCell;

@end

@implementation SelectListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"屏幕方向";
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ClickJumpTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([ClickJumpTableViewCell class])];

}

#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ClickJumpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ClickJumpTableViewCell class])];
    cell.titleString = self.dataList[indexPath.row].titleString;
    cell.tintColor = mainColor;
    if (self.dataList[indexPath.row].valueNumber == self.currentSelectCellModel.valueNumber) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.currentSelectCell = cell;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.currentSelectCell.accessoryType = UITableViewCellAccessoryNone;
    ClickJumpTableViewCell *cell = (ClickJumpTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.currentSelectCell = cell;
    self.currentSelectCellModel = self.dataList[indexPath.row];
    
    if (self.selectListCellBlock) {
        self.selectListCellBlock(self.currentSelectCellModel);
    }
}

@end
