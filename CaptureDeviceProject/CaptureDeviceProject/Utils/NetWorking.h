//
//  NetWorking.h
//  QingShanProject
//
//  Created by gunmm on 2018/5/4.
//  Copyright © 2018年 gunmm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SuccessBlock)(id result);
typedef void (^FailedBlock)(NSString *errorResult);

@interface NetWorking : NSObject

+ (void)bgPostDataWithParameters:(NSDictionary *)paramets withUrl:(NSString *)urlstr withBlock:(SuccessBlock)block withFailedBlock:(FailedBlock)fBlock;

@end
