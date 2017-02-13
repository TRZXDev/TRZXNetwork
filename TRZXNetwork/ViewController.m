//
//  ViewController.m
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/6.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import "ViewController.h"
#import "TRZXNetwork.h"


//static NSString *const dataUrl = @"http://www.qinto.com/wap/index.php?ctl=article_cate&act=api_app_getarticle_cate&num=1&p=1";
static NSString *const dataUrl = @"/api/map/city/findAllList/";
static NSString *const downloadUrl = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";



@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *networkData;
@property (weak, nonatomic) IBOutlet UITextView *cacheData;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatus;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;


/** 是否开启缓存*/
@property (nonatomic, assign, getter=isCache) BOOL cache;

/** 是否开始下载*/
@property (nonatomic, assign, getter=isDownload) BOOL download;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.


    if ([TRZXNetwork isNetwork]) {

        [self getData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:dataUrl];
        NSLog(@"有网络,请求网络数据");

    }else{

        self.networkData.text = @"没有网络";
        [self getData:YES url:dataUrl];
        NSLog(@"无网络,加载缓存数据");

    }


}

#pragma mark - 下载

- (IBAction)download:(UIButton *)sender {

    static NSURLSessionTask *task = nil;
    //开始下载
    if(!self.isDownload)
    {
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];

        task = [TRZXNetwork downloadWithURL:downloadUrl fileDir:@"Download" progressBlock:^(int64_t bytesRead, int64_t totalBytes) {

            CGFloat stauts = 100.f * bytesRead/totalBytes;
            self.progress.progress = stauts/100.f;

            NSLog(@"下载进度 :%.2f%%,,%@",stauts,[NSThread currentThread]);


        } callbackBlock:^(id response, NSError *error) {

            if (error) {

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载失败"
                                                                    message:[NSString stringWithFormat:@"%@",error]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil];
                [alertView show];
                NSLog(@"error = %@",error);

            }else{

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成!"
                                                                    message:[NSString stringWithFormat:@"文件路径:%@",response]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil];
                [alertView show];
                [self.downloadBtn setTitle:@"重新下载" forState:UIControlStateNormal];
                NSLog(@"filePath = %@",response);

            }



        }];


    }
    //暂停下载
    else
    {
        self.download = NO;
        [task suspend];
        self.progress.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }



}

#pragma mark - 缓存开关
- (IBAction)isCache:(UISwitch *)sender {

    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];

    [self getData:sender.isOn url:dataUrl];
}


#pragma  mark - 获取数据
- (void)getData:(BOOL)isOn url:(NSString *)url
{

    //自动缓存
    if(isOn)
    {
        self.cacheStatus.text = @"缓存打开";
        self.cacheSwitch.on = YES;


        [TRZXNetwork requestWithUrl:url params:nil method:GET cachePolicy:NetworkingReloadIgnoringLocalCacheData callbackBlock:^(id response, NSError *error) {

            self.cacheData.text = [self jsonToString:response];

            
            
        }];

    }
    //无缓存
    else
    {
        self.cacheStatus.text = @"缓存关闭";
        self.cacheSwitch.on = NO;
        self.cacheData.text = @"";


        [TRZXNetwork requestWithUrl:url params:nil method:GET cachePolicy:NetworkingReloadIgnoringLocalCacheData callbackBlock:^(id response, NSError *error) {

            self.networkData.text = [self jsonToString:response];



        }];


    }

}





/**
 *  json转字符串
 */
- (NSString *)jsonToString:(NSDictionary *)dic
{
    if(!dic){
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
