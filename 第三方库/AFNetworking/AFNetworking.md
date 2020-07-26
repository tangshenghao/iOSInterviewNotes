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

<br />

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

<br />

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

实现文件中，重要的是实现网络请求的方法

```
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {

		// 通过session和request生成task
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
		// 将task和回调block绑定到task的代理中
    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];

    return dataTask;
}

- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
              downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
             completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{

		// 生成对应的task管理类
    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:dataTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;

    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
    // 通过dataTask设置代理类
    [self setDelegate:delegate forTask:dataTask];
		// 指定上传和下载回调block
    delegate.uploadProgressBlock = uploadProgressBlock;
    delegate.downloadProgressBlock = downloadProgressBlock;
}

// 设置task代理类
- (void)setDelegate:(AFURLSessionManagerTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
    // 判断是否空异常
    NSParameterAssert(task);
    NSParameterAssert(delegate);
		// 加锁
    [self.lock lock];
    // 通过taskIdentifier为key存储task代理类
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    // 给task添加监听
    [self addNotificationObserverForTask:task];
    [self.lock unlock];
}
```

其中AFURLSessionManagerTaskDelegate负责了AFURLSessionManager中监听的NSURLSession的一些代理实现和回调的业务逻辑。

dataTaskWithRequest的方法返回生成的task，回到AFHTTPSessionManager将调用

```
[dataTask resume];
```

触发HTTP请求调用。

<br />

#### 1.3 网络状态监听模块

网络状态监听模块文件里，只有AFNetworkReachabilityManager类，和其他模块没有依赖。

```
typedef NS_ENUM(NSInteger, AFNetworkReachabilityStatus) {
    AFNetworkReachabilityStatusUnknown          = -1,
    AFNetworkReachabilityStatusNotReachable     = 0,
    AFNetworkReachabilityStatusReachableViaWWAN = 1,
    AFNetworkReachabilityStatusReachableViaWiFi = 2,
};
```

能监听4种状态，未知、不能联通网络、移动数据流量、Wi-Fi。

使用方式很简单，就是通过单例初始化方法创建后，通过设置对应的回调block即可。

其中开始监听的源码如下：

```
- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }
		// 设置回调block
    __weak __typeof(self)weakSelf = self;
    AFNetworkReachabilityStatusCallback callback = ^(AFNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        
        return strongSelf;
    };
		// 使用系统的SCNetworkReachability监听网络
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, AFNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

   // 启动时先通知一遍网络状态 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            AFPostReachabilityStatusChange(flags, callback);
        }
    });
}
```

以上就是网络监听模块的启动实现。

<br />

#### 1.4 网络安全模块

该模块只有AFSecurityPolicy一个类，具体实现的功能时完成HTTPS认证，是对系统库<Security/Security.h>的进一步封装。AFNetWorking的默认证书认证流程是客户端单项认证，加入需要双向验证，则服务器和客户端都需要发送数字证书给对方验证，需要用户自行实现。

AFSecurityPolicy的三种验证模式

```
typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,  			  // 无条件信任服务器的证书
    AFSSLPinningModePublicKey,	  // 会对服务器返回的证书种的PublicKey进行验证
    AFSSLPinningModeCertificate,	// 会对服务器返回的证书同本地证书全部进行验证
};
```

然后头文件包含以下属性

```
// 返回SSL Pinning的类型，默认是AFSSLPinningModeNone
@property (readonly, nonatomic, assign) AFSSLPinningMode SSLPinningMode;

// 保存所有可用做校验证书的集合，evaluateServerTrush:forDomain:就会返回true，表示通过校验
@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

// 允许使用无效或过期的证书，默认是NO不允许
@property (nonatomic, assign) BOOL allowInvalidCertificates;

// 是否校验证书种的域名，默认是YES
@property (nonatomic, assign) BOOL validatesDomainName;
```

以下是在AFURLSessionManager中实现的证书挑战代码

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    BOOL evaluateServerTrust = NO;
    // 默认类型
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    // 是否实现自定义的验证流程
    if (self.authenticationChallengeHandler) {
        
        id result = self.authenticationChallengeHandler(session, task, challenge, completionHandler);
        if (result == nil) {
            return;
        } else if ([result isKindOfClass:NSError.class]) {
            objc_setAssociatedObject(task, AuthenticationChallengeErrorKey, result, OBJC_ASSOCIATION_RETAIN);
            // 错误 取消挑战 取消连接
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        } else if ([result isKindOfClass:NSURLCredential.class]) {
        		// 证书挑战
            credential = result;
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else if ([result isKindOfClass:NSNumber.class]) {
            disposition = [result integerValue];
            NSAssert(disposition == NSURLSessionAuthChallengePerformDefaultHandling || disposition == NSURLSessionAuthChallengeCancelAuthenticationChallenge || disposition == NSURLSessionAuthChallengeRejectProtectionSpace, @"");
            // 获取服务器验证方式
            evaluateServerTrust = disposition == NSURLSessionAuthChallengePerformDefaultHandling && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
        } else {
            @throw [NSException exceptionWithName:@"Invalid Return Value" reason:@"The return value from the authentication challenge handler must be nil, an NSError, an NSURLCredential or an NSNumber." userInfo:nil];
        }
    } else {
    		// 获取服务器验证方式
        evaluateServerTrust = [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
    }
	
    if (evaluateServerTrust) {
        if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
        		// 证书挑战
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            objc_setAssociatedObject(task, AuthenticationChallengeErrorKey,
                                     [self serverTrustErrorForServerTrust:challenge.protectionSpace.serverTrust url:task.currentRequest.URL],
                                     OBJC_ASSOCIATION_RETAIN);
            // 取消挑战，取消连接
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
		// 完成挑战，将信任凭证返回给服务器
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
```

证书认证的核心代码如下：

```
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
		// 异常情况判断
    if (domain && self.allowInvalidCertificates && self.validatesDomainName && (self.SSLPinningMode == AFSSLPinningModeNone || [self.pinnedCertificates count] == 0)) {
        NSLog(@"In order to validate a domain name for self signed certificates, you MUST use pinning.");
        return NO;
    }
		// 创建安全策略，如果需要对域名进行验证，则创建附带入参域名的SSL安全策略，否则创建一个基于X.509的安全策略
    NSMutableArray *policies = [NSMutableArray array];
    if (self.validatesDomainName) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
	  // 将创建的安全策略加入到服务器给予的信任评估中，这个评估认证将会和本地的证书或者公钥进行评估得出结果
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
	  // AFSSLPinningModeNode的情况，不会进行公钥或证书的认证，只确保服务器的信任评估是否有效或者用户设置允许无效证书，那么也会直接返回通过。
    if (self.SSLPinningMode == AFSSLPinningModeNone) {
        return self.allowInvalidCertificates || AFServerTrustIsValid(serverTrust);
    } else if (!self.allowInvalidCertificates && !AFServerTrustIsValid(serverTrust)) {
        return NO;
    }
    // 不同模式的对应的认证
    switch (self.SSLPinningMode) {
        case AFSSLPinningModeCertificate: {
        // 验证本地证书和服务器发过来的信任进行判断
        // 这里本地使用的证书可能很多个，转换CFData存入
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in self.pinnedCertificates) {
                [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
            }
            // 将pinnedCertificates设置成需要参与验证的锚点证书。
            // 验证的数字证书是由锚点证书对应CA或CA签发的
            // 是该证书本身，则信任该证书，调用SecTrustEvaluate来验证。
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);

            if (!AFServerTrustIsValid(serverTrust)) {
                return NO;
            }

            // obtain the chain after being validated, which *should* contain the pinned certificate in the last position (if it's the Root CA)
            NSArray *serverCertificates = AFCertificateTrustChainForServerTrust(serverTrust);
            // 连理证书链
            for (NSData *trustChainCertificate in [serverCertificates reverseObjectEnumerator]) {
            // 如果包含本地证书，说明是有效的
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    return YES;
                }
            }
            
            return NO;
        }
        case AFSSLPinningModePublicKey: {
            // 验证本地公钥和服务器发过来的信任证书进行判断
            NSUInteger trustedPublicKeyCount = 0;
            // 获取服务器公钥链
            NSArray *publicKeys = AFPublicKeyTrustChainForServerTrust(serverTrust);
						// 遍历公钥链 在本地查找合适的公钥，如果有至少一个符合，则验证通过
            for (id trustChainPublicKey in publicKeys) {
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustedPublicKeyCount += 1;
                    }
                }
            }
            return trustedPublicKeyCount > 0;
        }
            
        default:
            return NO;
    }
    
    return NO;
}
```

以上就是安全模块中HTTPS的验证处理。

<br />

#### 1.5 数据解析模块

该模块里面包含着请求和响应的协议编码等处理。

