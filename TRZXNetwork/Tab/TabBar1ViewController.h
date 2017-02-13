//
//  TabBar1ViewController.h
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/10.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TabBar1ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)requestDataBtn:(id)sender;
- (IBAction)emptyDataBtn:(id)sender;

@end
