//
//  UserViewModel.m
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/10.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import "UserViewModel.h"
#import "TRZXNetwork.h"
#import "MJExtension.h"
static NSString *const url = @"/api/map/city/findAllList/";
@implementation UserViewModel


#pragma mark - Getter / Setter

// 采用懒加载的方式来配置网络请求
- (RACSignal *)requestSignal {

    if (!_requestSignal) {

        _requestSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {


            [TRZXNetwork requestWithUrl:url params:self.parameters method:GET cachePolicy:NetworkingReloadIgnoringLocalCacheData callbackBlock:^(id response, NSError *error) {

                if (response) {

                    self.dataSource = [City mj_objectArrayWithKeyValuesArray:response[@"list"]];
                    [subscriber sendNext:self.dataSource];
                    [subscriber sendCompleted];

                }else{
                    [subscriber sendError:error];
                }
            }];

            // 在信号量作废时，取消网络请求
            return [RACDisposable disposableWithBlock:^{

                [TRZXNetwork cancelRequestWithURL:url];
            }];
        }];
    }
    return _requestSignal;
}




@end
