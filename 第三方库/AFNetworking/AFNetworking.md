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

该模块只有AFSecurityPolicy一个类，具体实现的功能是完成HTTPS认证，是对系统库<Security/Security.h>的进一步封装。AFNetworking的默认证书认证流程是客户端单项认证，加入需要双向验证，则服务器和客户端都需要发送数字证书给对方验证，需要用户自行实现。

AFSecurityPolicy的三种验证模式

```
typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,  			  // 无条件信任服务器的证书
    AFSSLPinningModePublicKey,	  // 会对服务器返回的证书中的PublicKey进行验证
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

// 是否校验证书中的域名，默认是YES
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
            // 证书链
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

该模块里面包含着请求和响应的协议编码等处理。该模块只有两个类，AFURLRequestSerialization和AFURLResponseSerialization，用于处理发送和响应。

##### 1.5.1 AFURLRequestSerialization

AFURLRequestSerialization是个协议，文件里面主要的类是AFHTTPRequestSerializer，同时有两个子类，分别是AFJSONRequestSerializer和AFPropertyListRequestSerializer。这三个类都遵循了AFURLRequestSerialization协议，然后都实现了requestBySerializingRequest方法。

在AFHTTPRequestSerializer中实现如下：

```
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
		// 设置头部
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
		// 参数序列化处理
    NSString *query = nil;
    if (parameters) {
    		// 如果实现了自定义序列化 则执行自定义序列化
        if (self.queryStringSerialization) {
            NSError *serializationError;
            query = self.queryStringSerialization(request, parameters, &serializationError);

            if (serializationError) {
                if (error) {
                    *error = serializationError;
                }

                return nil;
            }
        } else {
        		// 否则则使用AF中带的序列化操作
            switch (self.queryStringSerializationStyle) {
                case AFHTTPRequestQueryStringDefaultStyle:
                    query = AFQueryStringFromParameters(parameters);
                    break;
            }
        }
    }
		// GET，HEAD，DELETE拼接在URL之后
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        if (query && query.length > 0) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
        }
    } else {
    	  // 如果不是，则需要设置Content-Type头部，并把query放到body中
        // #2864: an empty string is a valid x-www-form-urlencoded payload
        if (!query) {
            query = @"";
        }
        // AFHTTPRequestSerializer中定义的是application/x-www-form-urlencoded
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        }
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }

    return mutableRequest;
}
```

在AFJSONRequestSerializer中实现如下：

```
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);
		// 如果是GET、HEAD、DELETE则调用父类的方法
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
		// 设置头参数
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    if (parameters) {
    		// 如果外部没定义Content-Type 则定义application/json为Content-Type
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
				// 如果parameters不是json参数则返回错误信息
        if (![NSJSONSerialization isValidJSONObject:parameters]) {
            if (error) {
                NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The `parameters` argument is not valid JSON.", @"AFNetworking", nil)};
                *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
            return nil;
        }
				// 序列化json，在request中设置body
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error];
        
        if (!jsonData) {
            return nil;
        }
        
        [mutableRequest setHTTPBody:jsonData];
    }

    return mutableRequest;
}
```

在AFPropertyListRequestSerializer中实现如下：

```
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);
		// 如果是HEAD、GET、DELETE则调用父类的方法
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
		// 设置头部信息
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
		
    if (parameters) {
    		// 如果没设置Content-Type，则设置成application/x-plist
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-plist" forHTTPHeaderField:@"Content-Type"];
        }
				// 转成NSDATA并设置到httpbody中
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:parameters format:self.format options:self.writeOptions error:error];
        
        if (!plistData) {
            return nil;
        }
        
        [mutableRequest setHTTPBody:plistData];
    }

    return mutableRequest;
}
```

其中在AFHTTPRequestSerializer初始化时，设置了一些默认的参数

```
// Accept-Language HTTP Header; see 
http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
// Accept-Language 系统语言
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];
// userAgent 客户端信息 一般是bundleid/版本信息/屏幕分辨率的倍数等信息
NSString *userAgent = nil;
#if TARGET_OS_IOS
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
[self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
// 设置默认的只需拼接到URL的HTTP方法
self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
```

以上就是AFURLRequestSerialization序列化的一些处理。

<br />

##### 1.5.2 AFURLResponseSerialization

AFURLResponseSerialization也是个协议，是HTTP响应序列化的工具类，与上小节的AFURLRequestSerialization类似，主要是AFHTTPResponseSerializer类，并且该类有6个子类。

每一个AFHTTPResponseSerializer的子类在初始化都设定了acceptableContentTypes这个属性，例如AFJSONResponseSerializer

```
self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
```

而AFHTTPResponseSerializer在初始化时会设定acceptableStatusCodes，用于作为请求响应成功的判断200-299的响应码

```
self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
```

与上小节一样，不同的子类对应的不同的响应contentType，然后对应不同的contentType来处理响应的数据，例如AFJSONResponseSerializer中

```
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
		// 异常判断
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || AFErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, AFURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742
    // 空数据判断
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    
    if (data.length == 0 || isSpace) {
        return nil;
    }
    
    NSError *serializationError = nil;
    // json序列化处理响应数据，转成json对应的OC对象
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:&serializationError];

    if (!responseObject)
    {
        if (error) {
            *error = AFErrorWithUnderlyingError(serializationError, *error);
        }
        return nil;
    }
    // 是否移除值是NULL的数据
    if (self.removesKeysWithNullValues) {
        return AFJSONObjectByRemovingKeysWithNullValues(responseObject, self.readingOptions);
    }
		
    return responseObject;
}
```

所有子类对应的响应contentType处理如下：

| Class                            | Accept                                                       | Serializer                  |
| -------------------------------- | ------------------------------------------------------------ | --------------------------- |
| AFJSONResponseSerializer         | application/json,text/json,text/javascript                   | NSJSONSerialization         |
| AFXMLParserResponseSerializer    | application/xml,text/xml                                     | NSXMLParser                 |
| AFXMLDocumentResponseSerializer  | application/xml,text/xml                                     | NSXMLDocument               |
| AFPropertyListResponseSerializer | application/x-plist                                          | NSPropertyListSerialization |
| AFImageResponseSerializer        | image/tiff,image/jpeg,image/gif,image/png,image/ico,image/x-icon,image/bmp,image/x-bmp,image/x-xbitmap,image/x-win-bitmap | NSBitmapImageRep            |
| AFCompoundResponseSerializer     | 多种类型的集合                                               | -                           |

以上就是数据解析模块的内容。

<br />

#### 1.6 UI层相关模块

该模块包含了

网络下载图像的处理，缓存下载等流程。

UIButton和UIImageView的异步下载并显示等处理。

status bar显示网络状态loading处理。

UIProgressView进度条网络进度显示处理。

UIRefreshControl系统上拉刷新网络处理。

WKWebView网络监听和进度处理。

UIKit就不具体分析源码了。

<br />

