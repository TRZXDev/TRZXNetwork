//
//  UserViewModel.h
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/10.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>
#import "City.h"

@interface UserViewModel : NSObject
@property (strong, nonatomic) NSDictionary *parameters; ///  配置网络请求参数
@property (strong, nonatomic) RACSignal *requestSignal; ///< 网络请求信号量
@property (strong, nonatomic) NSMutableArray *dataSource; ///< tableView的数据源

@end
