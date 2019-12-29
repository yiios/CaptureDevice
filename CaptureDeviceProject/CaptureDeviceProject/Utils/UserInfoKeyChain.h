//
//  UserInfoKeyChain.h
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/12/27.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserInfoKeyChain : NSObject

@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *downLoadTime;
@property (nonatomic, copy) NSString *expirationTime;
@property (nonatomic, copy) NSString *isCreate;


+ (instancetype)keychainInstance;

+ (NSError *)clearKeychain;

- (NSError *)saveToKeychain;

@end

NS_ASSUME_NONNULL_END
