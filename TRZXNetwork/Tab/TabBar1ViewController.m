//
//  TabBar1ViewController.m
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/10.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import "TabBar1ViewController.h"
#import "UserViewModel.h"
#import "User.h"
#import "TRZXNetwork.h"
@interface TabBar1ViewController ()


@property (strong, nonatomic) UserViewModel *userViewModel;


@end

@implementation TabBar1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    [self sendRequest];



    NSDictionary *params = @{@"requestType":@"New_Schoole_Api",
                             @"apiType":@"homeV2"};

    [TRZXNetwork requestWithUrl:nil params:params method:GET cachePolicy:NetworkingReloadIgnoringLocalCacheData callbackBlock:^(id response, NSError *error) {


    }];





}


// 发起请求
- (void)sendRequest {

    [self.userViewModel.requestSignal subscribeNext:^(NSMutableArray *lists) {

        // 请求完成后，更新UI

        [self.tableView reloadData];


    } error:^(NSError *error) {
        // 如果请求失败，则根据error做出相应提示
        
    }];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    static NSString *cellID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }

    // 将数据赋值给cell的vm
    // cell接收到vm修改以后，就会触发初始时设置的信号量
    NSArray *cities = self.userViewModel.dataSource[indexPath.section];
    City *city = cities[indexPath.row];
    cell.textLabel.text = city.name;
    return cell;

}




#pragma mark - UITableViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{

    return self.userViewModel.dataSource.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    NSArray *cities = self.userViewModel.dataSource[section];
    return cities.count;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Lazy Load

- (UserViewModel *)userViewModel {

    if (!_userViewModel) {
        _userViewModel = [UserViewModel new];
    }
    return _userViewModel;
}

- (IBAction)requestDataBtn:(id)sender {

    [self sendRequest];

}

- (IBAction)emptyDataBtn:(id)sender {

    [self.userViewModel.dataSource removeAllObjects];


}
@end
