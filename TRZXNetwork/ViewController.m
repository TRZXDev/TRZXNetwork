//
//  ViewController.m
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/6.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import "ViewController.h"
#import "TRZXNetwork.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSMutableDictionary *headers = [[NSMutableDictionary alloc]init];
    [headers setValue:@"7d841879eb22e804e05e937c4c960889" forKey:@"token"];
    [headers setValue:@"d8c86c8f343e4de6a9faab7e148bed63" forKey:@"userId"];
    [headers setValue:@"iOS" forKey:@"equipment"];

    // 配置请求头
    [TRZXNetwork configHttpHeaders:headers];
    [TRZXNetwork configWithBaseURL:@"http://api.mmwipo.com/"];


    
    [TRZXNetwork requestWithUrl:@"/api/map/city/findAllList/" params:nil isCache:YES method:GET callbackBlock:^(id response, NSError *error) {






        
    }];


/*
    [TRZXNetwork requestWithUrl:@"http://123.57.188.187/eliteall/3187/hosts/openapi/api.php?token=dfad3fe6a365776d469cbfc05ae24079&cust_id=10288&display_id=e732270d08dd610c0e930dd4bc5084da&appkey=46982266432&timer=1468204513309&type=projectAPI&method=eliteall.project&cust_class=3&username=15202153577&class=getcustomers&classtype=investors&search=&perpage=1&createtimer=0" params:nil isCache:YES method:POST callbackBlock:^(id response, NSError *error) {

        



    }];

*/



}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
