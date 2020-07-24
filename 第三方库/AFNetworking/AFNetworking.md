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

最主要的是AFHTTPSessionManager和AFURLSessionManager，其中AFHTTPSessionManager是AFURLSessionManager的子类。

