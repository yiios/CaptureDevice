//
//  BaseDeviceManager.m
//  CaptureDeviceProject
//
//  Created by gunmm on 2019/8/24.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "BaseDeviceManager.h"
#import "NetWorking.h"
#import "sys/utsname.h"

@implementation BaseDeviceManager

+ (void)uploadDeviceInfo {
    NSString *urlStr = @"updatePingMuUser";
    
    UIDevice *device = [[UIDevice alloc] init];
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];
    if (deviceId.length == 0) {
        urlStr = @"addPingMuUser";
        deviceId = [[NSUUID UUID] UUIDString];
    }
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *currentVersion = [NSString stringWithFormat:@"%@.%@", version, build];
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:deviceId forKey:@"deviceId"];
    [param setObject:currentVersion forKey:@"pingMuVersion"];
    [param setObject:device.systemVersion forKey:@"systemVersion"];
    [BaseDeviceManager checkString:device.systemVersion];
    [param setObject:device.name forKey:@"name"];
    [param setObject:device.model forKey:@"model"];
    [param setObject:device.localizedModel forKey:@"localizedModel"];
    [param setObject:device.systemName forKey:@"systemName"];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    [param setObject:deviceString forKey:@"deviceString"];
    [param setObject:@"1" forKey:@"signValue"];
#if DEBUG
    [param setObject:@"0" forKey:@"signValue"];
#endif

    [NetWorking bgPostDataWithParameters:param withUrl:urlStr withBlock:^(id result) {
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"deviceId"];
    } withFailedBlock:^(NSString *errorResult) {
    }];
    
}

+ (void)uploadPushUrl:(NSString *)pushUrlStr {
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];
    if (deviceId.length == 0) {
        return;
    }
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:deviceId forKey:@"deviceId"];
    [param setObject:pushUrlStr? : @"" forKey:@"lastUrl"];
    
    [NetWorking bgPostDataWithParameters:param withUrl:@"updataPushUrl" withBlock:^(id result) {
    } withFailedBlock:^(NSString *errorResult) {
    }];
}

+ (void)checkString:(NSString *)versionStr {
    if ([versionStr containsString:@"13.0"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"iOS13.0系统有BUG，本软件暂不支持，请升级手机系统后重试"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
            exit(1);
        }];
        [alert addAction:defaultAction];
        [[NavBgImage getCurrentVC] presentViewController:alert animated:YES completion:nil];
    }
}

@end
