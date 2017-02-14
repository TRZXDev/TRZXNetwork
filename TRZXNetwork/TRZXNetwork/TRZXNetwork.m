//
//  TRZXNetwork.m
//  TRZXNetwork
//
//  Created by N年後 on 2017/2/6.
//  Copyright © 2017年 TRZX. All rights reserved.
//

#import "TRZXNetwork.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "TRZXNetworkCache.h"

#define TRZXLog(FORMAT, ...) fprintf(stderr, "[%s:%d行] %s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);  //如果不需要打印数据, 注释掉NSLog

static NSMutableArray      *requestTasks;//管理网络请求的队列

static NSMutableDictionary *headers; //请求头的参数设置

static NSString *baseURL = @"http://api.kipo.mmwipo.com/"; //baseURL
static NSString *newBaseURL = @"http://api.mmwipo.com/"; //baseURL
static NSString *kBaseURLStr_Path = @"api/mobile/center?equipment=ios";


static NetworkStatus       networkStatus; //网络状态

static NSTimeInterval      requestTimeout = 15;//请求超时时间

static NSString * const ERROR_IMFORMATION = @"网络出现错误，请检查网络连接";

#define ERROR [NSError errorWithDomain:@"请求失败" code:-999 userInfo:@{ NSLocalizedDescriptionKey:ERROR_IMFORMATION}]




@implementation TRZXNetwork


+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasks == nil) {
            requestTasks = [[NSMutableArray alloc] init];
        }
    });
    return requestTasks;
}

+ (BOOL)isNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (void)configHttpHeaders:(NSDictionary *)httpHeaders {
    headers = httpHeaders.mutableCopy;
}

/**
 *  配置请求头
 *
 *  @param baseURL 请求头参数
 */
+ (void)configWithBaseURL:(NSString *)baseURL{
    baseURL = baseURL;
}

+ (void)configWithNewBaseURL:(NSString *)baseURL{

    newBaseURL = baseURL;
}



+ (void)setupTimeout:(NSTimeInterval)timeout {
    requestTimeout = timeout;
}



+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[URLSessionTask class]]) {
                [task cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    };
}

+ (void)cancelRequestWithURL:(NSString *)url {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[URLSessionTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    };
}





+ (AFHTTPSessionManager *)newManager{

    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager manager]initWithBaseURL:[NSURL URLWithString:newBaseURL]];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    [serializer setRemovesKeysWithNullValues:YES];

    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    manager.requestSerializer.timeoutInterval = requestTimeout;

    [self detectNetworkStaus];

    return manager;
}


+ (AFHTTPSessionManager *)manager{

    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager manager]initWithBaseURL:[NSURL URLWithString:baseURL]];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    [serializer setRemovesKeysWithNullValues:YES];

    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    manager.requestSerializer.timeoutInterval = requestTimeout;

    [self detectNetworkStaus];

    return manager;
}




/**
 *  统一请求接口(不带缓存)
 *
 *  @param url                  请求路径
 *  @param params               拼接参数
 *  @param method               请求方式（0为POST,1为GET）
 *  @param callbackBlock        请求回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (URLSessionTask *)requestWithUrl:(NSString *)url
                            params:(NSDictionary *)params
                            method:(NetworkMethod)method
                     callbackBlock:(requestCallbackBlock)callbackBlock{
    return [self requestWithUrl:url params:params method:method cachePolicy:NetworkingReloadIgnoringLocalCacheData callbackBlock:callbackBlock];
}



/**
 *  统一请求接口
 *
 *  @param url                  请求路径
 *  @param params               拼接参数
 *  @param method               请求方式（0为POST,1为GET）
 *  @param cachePolicy          是否使用缓存
 *  @param callbackBlock        请求回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (URLSessionTask *)requestWithUrl:(NSString *)url
                            params:(NSDictionary *)params
                            method:(NetworkMethod)method
                       cachePolicy:(NetworkingRequestCachePolicy)cachePolicy
                     callbackBlock:(requestCallbackBlock)callbackBlock{

    AFHTTPSessionManager *manager ;
    URLSessionTask *session;


    //=======================================旧的API请求方式

    if (params[@"requestType"] !=nil) {

        manager = [self manager];

        NSString *token = headers[@"token"];
        NSString *userId = headers[@"userId"];
        url = [kBaseURLStr_Path stringByAppendingString:baseURL];
        if (token!=nil&&userId!=nil) { //
            url = [url stringByAppendingFormat:@"&token=%@&userId=%@",token,userId];
        }
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    }else{

        manager = [self newManager];


    //======================================新的API请求方式


    //处理中文和空格问题
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //拼接
    NSString * cacheUrl = [self urlDictToStringWithUrlStr:url WithDict:params];

    NSString *versionStr = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    //版本号
    //kCFBundleIdentifierKey
    [params setValue:versionStr forKey:@"version"];
    //区分来源
    [params setValue:@"ios" forKey:@"os"];
    //当前使用的语言
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    if (currentLanguage != nil && [currentLanguage length]>0) {
        [params setValue:currentLanguage forKey:@"language"];
    }



    //根据网址从Cache中取数据
    id cacheData = [TRZXNetworkCache httpCacheForURL:url parameters:params];

    switch (cachePolicy) {
        case NetworkingReturnCacheDataThenLoad: { // 先返回缓存，同时请求
            if (cacheData) {
                callbackBlock(cacheData,nil);
            }
            break;
        }
        case NetworkingReloadIgnoringLocalCacheData: { // 忽略本地缓存直接请求
            // 不做处理，直接请求
            break;
        }
        case NetworkingReturnCacheDataElseLoad: { // 有缓存就返回缓存，没有就请求
            if (cacheData) { // 有缓存
                callbackBlock(cacheData,nil);
                return session;
            }
            break;
        }
        case NetworkingReturnCacheDataDontLoad: { // 有缓存就返回缓存,从不请求（用于没有网络）
            if (cacheData) { // 有缓存
                callbackBlock(cacheData,nil);
            }
            return session; // 退出从不请求
        }
        default: {
            break;
        }
    }

        //================================================
        TRZXLog(@"URL=%@",cacheUrl);
        TRZXLog(@"params=%@",params==nil?@"无参数":params);

    }



    double start =  CFAbsoluteTimeGetCurrent();

    //    发起请求
    switch (method) {
        case GET:{


            if (networkStatus == NetworkStatusNotReachable ||  networkStatus == NetworkStatusUnknown) {
                callbackBlock ? callbackBlock(nil,ERROR) : nil;
                return nil;
            }

            session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {


            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                double end = CFAbsoluteTimeGetCurrent();
                TRZXLog(@"TRZXNetwork====%fs JSON字符串= %@",(end-start),[self jsonToString:responseObject]);

                [TRZXNetworkCache setHttpCache:responseObject URL:url parameters:params];
                callbackBlock ? callbackBlock(responseObject,nil) : nil;

                [[self allTasks] removeObject:task];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                callbackBlock ? callbackBlock(nil,error) : nil;
                TRZXLog(@">>>error  %@",error);

                [[self allTasks] removeObject:task];
            }];





            break;}
        case POST:{

            if (networkStatus == NetworkStatusNotReachable ||  networkStatus == NetworkStatusUnknown) {
                callbackBlock ? callbackBlock(nil,ERROR) : nil;

                return nil;
            }
            session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {


            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

                double end = CFAbsoluteTimeGetCurrent();
                TRZXLog(@"TRZXNetwork====%fs JSON字符串= %@",(end-start),[self jsonToString:responseObject]);

                [TRZXNetworkCache setHttpCache:responseObject URL:url parameters:params];
                callbackBlock ? callbackBlock(responseObject,nil) : nil;

                [[self allTasks] removeObject:task];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

                TRZXLog(@">>>error  %@",error);


                callbackBlock ? callbackBlock(nil,error) : nil;
                [[self allTasks] removeObject:task];
            }];


            break;}
        default:
            break;
    }


    if (session) {
        [requestTasks addObject:session];
    }
    return  session;

}






/**
 *  图片上传接口
 *
 *	@param image            图片对象
 *  @param url              请求路径
 *	@param name             图片名
 *	@param type             默认为image/jpeg
 *	@param params           拼接参数
 *	@param progressBlock    上传进度
 *  @param callbackBlock    请求回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (URLSessionTask *)uploadWithImage:(UIImage *)image
                                url:(NSString *)url
                               name:(NSString *)name
                               type:(NSString *)type
                             params:(NSDictionary *)params
                      progressBlock:(NetWorkingProgress)progressBlock
                      callbackBlock:(requestCallbackBlock)callbackBlock{


    AFHTTPSessionManager *manager = [self newManager];

    URLSessionTask *session = [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.4);

        NSString *imageFileName;

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

        formatter.dateFormat = @"yyyyMMddHHmmss";

        NSString *str = [formatter stringFromDate:[NSDate date]];

        imageFileName = [NSString stringWithFormat:@"%@.png", str];

        NSString *blockImageType = type;

        if (type.length == 0) blockImageType = @"image/jpeg";

        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:blockImageType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        callbackBlock ? callbackBlock(responseObject,nil) : nil;

        [[self allTasks] removeObject:task];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        callbackBlock ? callbackBlock(nil,error) : nil;

        [[self allTasks] removeObject:task];
    }];

    [session resume];

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;




}

/**
 *  文件上传接口
 *
 *  @param url              上传文件接口地址
 *  @param uploadingFile    上传文件路径
 *  @param progressBlock    上传进度
 *  @param callbackBlock    请求回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (URLSessionTask *)uploadFileWithUrl:(NSString *)url
                        uploadingFile:(NSString *)uploadingFile
                        progressBlock:(NetWorkingProgress)progressBlock
                        callbackBlock:(requestCallbackBlock)callbackBlock{

    AFHTTPSessionManager *manager = [self newManager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    URLSessionTask *session = nil;

    [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];

        callbackBlock ? callbackBlock(responseObject,nil) : nil;

        callbackBlock && error ? callbackBlock(nil,error) : nil;
    }];

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;


}

/**
 *  文件下载接口
 *
 *  @param url              下载文件接口地址
 *  @param saveToPath       存储目录
 *  @param progressBlock    下载进度
 *  @param callbackBlock    请求回调
 *
 *  @return 返回的对象可取消请求
 */
+ (URLSessionTask *)downloadWithUrl:(NSString *)url
                         saveToPath:(NSString *)saveToPath
                      progressBlock:(NetWorkingProgress)progressBlock
                      callbackBlock:(requestCallbackBlock)callbackBlock{

    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFHTTPSessionManager *manager = [self newManager];

    URLSessionTask *session = nil;

    session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progressBlock) {
            progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL URLWithString:saveToPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];

        callbackBlock ? callbackBlock(filePath.absoluteString,nil) : nil;

        callbackBlock && error ? callbackBlock(nil,error) : nil;
    }];

    [session resume];

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;

}


/**
 *  下载文件
 *
 *  @param URL      请求地址
 *  @param fileDir  文件存储目录(默认存储目录为Download)
 *  @param progressBlock 文件下载的进度信息
 *  @param callbackBlock    请求回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
 */
+ (URLSessionTask *)downloadWithURL:(NSString *)URL
                            fileDir:(NSString *)fileDir
                      progressBlock:(NetWorkingProgress)progressBlock
                      callbackBlock:(requestCallbackBlock)callbackBlock{

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];

    AFHTTPSessionManager *manager = [self newManager];
    URLSessionTask *session = nil;

    session = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        TRZXLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);

        //下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progressBlock ? progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount) : nil;
        });

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {

        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];

        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];

        TRZXLog(@"downloadDir = %@",downloadDir);
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];

    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

        [[self allTasks] removeObject:session];
        if(callbackBlock && error) {callbackBlock(nil,error) ; return ;};
        callbackBlock ? callbackBlock(filePath.absoluteString,nil /** NSURL->NSString*/) : nil;

    }];

    //开始下载
    [session resume];

    // 添加sessionTask到数组
    session ? [[self allTasks] addObject:session] : nil ;
    return session;

}



/**
 *  拼接post请求的网址
 *
 *  @param urlStr     基础网址
 *  @param parameters 拼接参数
 *
 *  @return 拼接完成的网址
 */
+ (NSString *)urlDictToStringWithUrlStr:(NSString *)urlStr WithDict:(NSDictionary *)parameters{
    if (!parameters) {
        return urlStr;
    }

    NSMutableArray *parts = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //接收key
        NSString *finalKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //接收值
        NSString *finalValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];


        NSString *part =[NSString stringWithFormat:@"%@=%@",finalKey,finalValue];

        [parts addObject:part];

    }];

    NSString *queryString = [parts componentsJoinedByString:@"&"];

    queryString = queryString ? [NSString stringWithFormat:@"?%@",queryString] : @"";

    NSString *pathStr = [NSString stringWithFormat:@"%@?%@",urlStr,queryString];

    return pathStr;
}


#pragma mark - 网络状态的检测
+ (void)detectNetworkStaus {
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable){
            networkStatus = NetworkStatusNotReachable;
        }else if (status == AFNetworkReachabilityStatusUnknown){
            networkStatus = NetworkStatusUnknown;
        }else if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi){
            networkStatus = NetworkStatusNormal;
        }
    }];
}


+ (void)updateRequestSerializerType:(SerializerType)requestType responseSerializer:(SerializerType)responseType {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    if (requestType) {
        switch (requestType) {
            case HTTPSerializer: {
                manager.requestSerializer = [AFHTTPRequestSerializer serializer];
                break;
            }
            case JSONSerializer: {
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                break;
            }
            default:
                break;
        }
    }
    if (responseType) {
        switch (responseType) {
            case HTTPSerializer: {
                manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                break;
            }
            case JSONSerializer: {
                manager.responseSerializer = [AFJSONResponseSerializer serializer];
                break;
            }
            default:
                break;
        }
    }
}


/**
 *  json转字符串
 */
+ (NSString *)jsonToString:(id)data
{
    if(!data) { return nil; }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


@end
