//
//  UserInfoKeyChain.m
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/12/27.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "UserInfoKeyChain.h"

@implementation UserInfoKeyChain

+ (instancetype)keychainInstance {
    NSError *error = nil;
    YYKeychainItem *item = [[YYKeychainItem alloc] init];
    item.service = [self keychainService];
    item.account = [self keychainAccount];
    item = [YYKeychain selectOneItem:item error:&error];
    if (error || !item) {
        
        
        
        return nil;
    }
    else {
        UserInfoKeyChain *userInfoKeyChain = [self modelWithJSON:item.password];
        return userInfoKeyChain;
    }
}

+ (NSError *)clearKeychain {
    NSError *error = nil;
    [YYKeychain deletePasswordForService:[self keychainService]
                                 account:[self keychainAccount]
                                   error:&error];
    return error;
}

- (NSError *)saveToKeychain {
    NSError *error = nil;
    [YYKeychain setPassword:[self modelToJSONString]
                 forService:[self.class keychainService]
                    account:[self.class keychainAccount]
                      error:&error];
    return error;
}

#pragma mark - keychain

+ (NSString *)keychainService {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey];
}

+ (NSString *)keychainAccount {
    return [NSString stringWithFormat:@"%@.currentUser", [self keychainService]];
}

@end
