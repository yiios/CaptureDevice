//
//  NetWorking.m
//  QingShanProject
//
//  Created by gunmm on 2018/5/4.
//  Copyright © 2018年 gunmm. All rights reserved.
//

#import "NetWorking.h"
#import <AFNetworking/AFNetworking.h>

@implementation NetWorking

+ (void)bgPostDataWithParameters:(NSDictionary *)paramets withUrl:(NSString *)urlstr withBlock:(SuccessBlock)block withFailedBlock:(FailedBlock)fBlock {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:paramets forKey:@"body"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager POST:[NetWorking netUrlWithStr:urlstr] parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *runStatus = [responseObject objectForKey:@"result_code"];
        if ([runStatus isEqualToString:@"1"]) {
            block(responseObject);
        } else {
            fBlock(@"error");
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error---%@",error);
        if ([[error.userInfo allKeys]containsObject:@"NSLocalizedDescription"]) {
            fBlock([error.userInfo objectForKey:@"NSLocalizedDescription"]);
        }else{
            fBlock(@"error");
        }
    }];
}


+ (NSString *)netUrlWithStr:(NSString *)url {
    return [NSString stringWithFormat:@"http://39.107.113.157:8080/QingShansProject/%@", url];
}

@end
