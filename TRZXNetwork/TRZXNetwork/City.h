//
//  City.h
//  TRZX
//
//  Created by N年後 on 2017/1/3.
//  Copyright © 2017年 Tiancaila. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface City : NSObject
@property (nonatomic, copy) NSString *citycode;
@property (nonatomic, copy) NSString *longitude;
@property (nonatomic, copy) NSString *latitude;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mid;


// 定位城市
@property (nonatomic, copy) NSString *adcode;
@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *province;


@end
