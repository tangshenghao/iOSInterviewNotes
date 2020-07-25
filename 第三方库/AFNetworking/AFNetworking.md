## AFNetworking

### 1 AFNetworking简介

AFNetworking是一个iOS开发者基本都会知道的网络请求框架。该框架能非常方便地实现http协议的请求，以及请求返回的转码处理，同时还包含了网络监听、证书认证、给UI异步网络加载图片等功能。

#### 1.1 AFNetworking源码结构

AFNetworking从文件夹上分为了五个模块，如下：

- NSURLSession - 通信模块，对NSURLSession的封装
- Reachability - 网络状态监听模块
- Security - 网络安全模块
- Serialization - 数据解析模块
- UIKit - UI层相关模块

接下来逐个模块解析



#### 1.2 通信模块

通信模块中AFCompatibilityMacros实现了一些宏的定义，这里不细说。

最主要的是AFHTTPSessionManager和AFURLSessionManager。其中AFHTTPSessionManager是AFURLSessionManager的子类。

##### 1.2.1 AFHTTPSessionManager

```
// 基础URL 便于不用每个接口都是用全路径
@property (readonly, nonatomic, strong, nullable) NSURL *baseURL;
// 请求的编码管理器 - 默认是 URL-form-encodes AFHTTPRequestSerializer 的格式
@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;
// 响应的编码管理器 - 默认是 AFJSONResponseSerializer json的响应格式
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;
// 安全策略
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
```

除了属性之外，头文件允许外部调用的方法为6个HTTP的Method：GET、HEADER、POST、PUT、DELETE、PATCH。其中POST有两个方法，一个是正常的POST请求，另外一个是上传使用的POST。除了上传是调用父类中的uploadTaskWithStreamedRequest之外，其余的方法都是先调用本类实现的dataTaskWithHTTPMethod方法。

现在看下具体实现：

```
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(nullable id)parameters
                                         headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                                         success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                         failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    // 设置header信息
    for (NSString *headerField in headers.keyEnumerator) {
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    if (serializationError) {
        if (failure) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
        }

        return nil;
    }
		// 调用父类的dataTaskWithRequest方法
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        } else {
            if (success) {
                success(dataTask, responseObject);
            }
        }
    }];

    return dataTask;
}
```

从上述来看，该类主要就是对父类的一层具体方法封装，同时4.x之后在函数上加入headers的字典参数，方便用于在header中需要传递特定信息的请求，例如带access-token等信息。

##### 1.2.1 AFURLSessionManager

接着看AFURLSessionManager，该类是框架中最为核心的类。该类是负责管理系统的NSURLSession类，并且实现了NSURLSession对应的代理协议。

```
// 管理的NSURLSession
@property (readonly, nonatomic, strong) NSURLSession *session;
// 用于回调的operation队列
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;
// 响应的编码管理器 - 默认是 AFJSONResponseSerializer json的响应格式 
@property (nonatomic, strong) id <AFURLResponseSerialization> responseSerializer;
// 安全策略
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
// 网络监测
@property (readwrite, nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
// 所有类型的task数组
@property (readonly, nonatomic, strong) NSArray <NSURLSessionTask *> *tasks;
// 数据请求的task数组
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDataTask *> *dataTasks;
// 上传的task数组
@property (readonly, nonatomic, strong) NSArray <NSURLSessionUploadTask *> *uploadTasks;
// 下载的task数组
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDownloadTask *> *downloadTasks;
// 完成block的GCD队列，不设置时使用主队列
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;
// 完成block的GCD group
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;
```

