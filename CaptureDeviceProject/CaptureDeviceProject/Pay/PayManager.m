//
//  PayManager.m
//  CaptureDeviceProject
//
//  Created by minzhe on 2019/12/27.
//  Copyright © 2019 minzhe. All rights reserved.
//

#import "PayManager.h"
#import <StoreKit/StoreKit.h>

@interface PayManager () <SKPaymentTransactionObserver, SKProductsRequestDelegate>



@end

@implementation PayManager

+ (instancetype)manager {
    static PayManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [PayManager new];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    });
    return instance;
}

- (void)getRequestAppleProduct {
    NSArray *product = [[NSArray alloc] initWithObjects:@"com.gunmm.month",nil];
    NSSet *nsset = [NSSet setWithArray:product];
    // 8.初始化请求
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    // 9.开始请求
    [request start];
}

#pragma mark ---SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *product = response.products;
    
    //如果服务器没有产品
    if([product count] == 0){
        NSLog(@"nothing");
        return;
    }
    
    SKProduct *requestProduct = nil;
    for (SKProduct *pro in product) {
        
        NSLog(@"%@", [pro description]);
        NSLog(@"%@", [pro localizedTitle]);
        NSLog(@"%@", [pro localizedDescription]);
        NSLog(@"%@", [pro price]);
        NSLog(@"%@", [pro productIdentifier]);
        
        // 11.如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
        if([pro.productIdentifier isEqualToString:@"com.gunmm.month"]){
            requestProduct = pro;
        }
    }
    NSLog(@"");
    
    // 12.发送购买请求
    SKPayment *payment = [SKPayment paymentWithProduct:requestProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)requestDidFinish:(SKRequest *)request {
    NSLog(@"信息反馈结束");
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"error:%@", error);

}

#pragma mark ---SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transaction {
    NSLog(@"------------");
    for(SKPaymentTransaction *tran in transaction){
        
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"已经购买过商品");
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            default:
                break;
        }
    }
}

@end
