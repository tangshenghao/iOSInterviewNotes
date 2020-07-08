## WKWebView

### 1 UIWebView和WKWebView

#### 1.1 需求背景

其实该篇介绍的内容只有WKWebView的其中一小部分，主要是自己项目中处理的一个方案。因为苹果审核要求，从20年4月份开始新上架的APP，不能使用UIWebView。已上架的应用到12月底开始不能使用UIWebView提交更新。所以项目需要用WKWebView替换UIWebView。

以上原因，项目中需要将原先旧的UIWebView的逻辑替换成用WKWebView来实现，同时使用WKWebView响应速度快，内存占用小，支持更多的HTML的特性。



#### 1.2 替换存在的问题

在原先的项目中，因为是物联网应用，对应的设备控制页，都是使用UIWebView作为了一个通用承载页面。所以里面有大量逻辑，替换过程中，主要有以下问题：

- 因旧版H5的项目较多，且后续使用了RN方案，大部分已没有工程师来维护。需要在不改动H5代码的情况下进行方案替换。
- 项目之前使用的原生与H5之间的交互，使用的是JavaScriptCore方式，而WKWebView在项目中的不是一个进程，不能获取到上下文，所以不能使用该种方式。
- H5与原生的交互方法有用到同步结果值返回的情况。



### 2 替换方案分析

#### 2.1 H5与原生的交互方式

分别从UIWebView和WKWebView与原生的交互方式进行分析。

**UIWebView**分为三种方式：

- URL拦截
- JavaScriptCore获取上下文
- JSExport协议



##### 2.1.1 URL拦截

URL拦截使用的是H5每次准备跳转到新的url时，对url进行分析，并截取内容从而处理原生的代码并截断H5的跳转。需要在代理的shouldStartLoadWithRequest方法中截取。

原生代码实现如下：

```
//JS发送给原生 - 截取URL法 - 不能带回调
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    //webview每次刷新跳转时都会回调
    NSLog(@"request:%@ , type:%ld", request.URL, (long)navigationType);
    if ([request.URL.scheme caseInsensitiveCompare:@"jsToOc"] == NSOrderedSame) {
        NSLog(@"拦截到了jsToOc的事件, 事件为: %@, 参数为：%@",request.URL.host, request.URL.query);
        return NO;
    }
    return YES;
}
```

JS代码实现如下：

```
function doSomeThing() {
    var url = "jsToOC://xxxx?aaaa=bbbb";
    window.location.href = url;
}
```

使用该种方法实现比较简单，但是并不能实现同步返回的功能，需要通过stringByEvaluatingJavaScriptFromString来发送结果给H5端，相当于异步处理。



##### 2.1.2  JavaScriptCore获取上下文

项目中原本采用的方案。可以获取上下文，获取到对应的内容，并且可以挂载方法，可以传入不同数量的参数。是根据JavaScriptCore框架来实现的。

原生代码实现如下：

```
JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    //可以指定参数，也可以不指定，不指定的话，JS可任意传递多个参数
    //挂载、监听该方法，相当于重写
    //注意内部是子线程
    //同时注意不要使用外部的context来处理，会循环引用，但是weak对JS不起效
    //可以同步返回数据
    context[@"JSToOC2"] = ^() {
        NSArray *args = [JSContext currentArguments];
        NSString *param1 = [args[0] toString];
        NSString *param2 = [args[1] toString];
        NSLog(@" 接收到了JS传递过来的事件，参数1 = %@，参数2 = %@ ",param1, param2);
        return @"xxxxx";
    };
```

JS代码实现如下：

```
function doSomeThing1() {
    //使用window调用和不使用都可以
    var result = window.JSToOC2("aaaaa", "bbbbbb");
    console.log(result);
}
```

原项目中，就是挂载了20+个方法。同时需要注意循环引用的问题。



##### 2.1.3  JSExport协议

该方案和上述一样也是基于JavaScriptCore框架实现，使用时需要遵循JSExport的协议，通过JSExportAs宏来挂载定义的方法。可以实现同步返回。JS需要通过OCJSBridge来调用。

原生代码实现如下：

```
@protocol OCJSExport <JSExport>

JSExportAs(jSToOC3, - (NSString *)jSToOC3WithParam:(NSString *)param type:(NSString *)type);

@end

@interface UIWebViewDemoViewController () <UIWebViewDelegate, OCJSExport>

//JS发送给原生 - 通过JSExport协议
- (NSString *)jSToOC3WithParam:(NSString *)param type:(NSString *)type {
    NSArray *args = [JSContext currentArguments];
    NSString *param1 = [args[0] toString];
    NSString *param2 = [args[1] toString];
    NSLog(@" 接收到了JS传递过来的事件，参数1 = %@，参数2 = %@ ",param1, param2);
    NSLog(@" 接收到了JS传递过来的事件2，参数1 = %@，参数2 = %@ ",param, type);
    //可以同步返回数据
    return @"xxaaaaa";
}
```

JS代码实现如下：

```
function doSomeThing2() {
    //使用window调用和不使用都可以
    var result = OCJSBridge.jSToOC3("aaaaa", "bbbbbb");
    console.log(result);
}
```

采用该种方式传入的参数需要与原生定义的参数匹配。



**WKWebView**也分为三种方式：

- URL拦截
- WKScriptMessageHandle协议
- WKUIDelegate协议

官方推荐使用WKScriptMessageHandle协议进行交互，但实际上却不能解决上节中提到的问题。



##### 2.1.4 URL拦截

原理和UIWebview一样，对url进行捕获并分析，同时处理原生代码并截断H5的跳转，在decidePolicyForNavigationAction协议方法中实现。

原生代码实现如下：

```
//协议拦截法
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    //加载前循环是否要跳转
    NSLog(@"wk=======decidePolicyForNavigationAction");
    NSLog(@"request:%@ ", navigationAction.request.URL);
    if ([navigationAction.request.URL.scheme caseInsensitiveCompare:@"jsToOC"] == NSOrderedSame) {
        NSLog(@"拦截到了jsToOc的事件, 事件为: %@, 参数为：%@",navigationAction.request.URL.host, navigationAction.request.URL.query);
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
```

JS代码实现如下：

```
function doSomeThing() {
    var url = "jsToOC://xxxx?aaaa=bbbb";
    window.location.href = url;
}
```

和UIWebView一样，无法实现同步返回的功能。



##### 2.1.5 WKScriptMessageHandle协议

使用该协议需要在WKUserContentController中添加方法。同时不能实现

同步返回功能。需要注意循环引用的问题，需要在退出前移除挂载的方法。

原生代码实现如下：

```
// 添加方法
WKUserContentController *userConnectController = [[WKUserContentController alloc] init];
    [userConnectController addScriptMessageHandler:self name:@"JSToOC2"];
...

//WKScriptMessageHandler方式
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"JSToOC2"]) {
        NSLog(@" 接收到了JS传递过来的事件，参数1 = %@，参数2 = %@ ",message.name, message.body);
    }
}

//移除挂载方法
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"JSToOC2"];
}
```

JS代码实现如下：

```
function doSomeThing1() {
        //使用messageHandlers调用
    window.webkit.messageHandlers.JSToOC2.postMessage("aaaaa", "bbbbbb");
}
```

从JS代码中可以看到，需要使用 window.webkit.messageHandlers.方法名.postMessage 方式来调用原生的方法，且不能同步返回，所以不适用于替换原项目。



##### 2.1.6 WKUIDelegate协议

该种方法是通过WKUIDelegate中的代理方法来实现，原本作用是给alert、confirm和prompt这三种方式的弹窗来做原生的交互。但其中prompt为带输入框的弹窗，使用这种方式可以实现输入结果同步返回的功能。

先看看普通的交互实现

原生代码实现如下：

```
//Prompt方式进行传递
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    NSLog(@" 接收到了JS传递过来的prompt事件，参数1 = %@，参数2 = %@ ",prompt ,defaultText);
    completionHandler(@"asdasd");
}
```

JS代码实现如下：

```
function doSomeThing2() {
    //使用window调用和不使用都可以
    var result = window.prompt("aaaaa", "bbbbbb");
    console.log(result);
}
```



其中JS的调用方式使用的是window.prompt，并且传递只能是两个参数，其中回调函数中的参数prompt对应JS的prompt中的第一个参数。defaultText对应第二个参数。通过代码可以看出，实现了同步返回的功能。

采用的方案就是使用该种方式，但是其中做了一些转换处理。



### 3 替换方案实现

采用Prompt方式，同步问题已经有解决方案。

现只需要考虑如何在H5端代码不用修改的情况完成切换。

也就是实现JS的调用能进行如下变化：

window.方法名(参数…)     转变成     window.prompt(方法名, 参数)

最开始想到的方式是将所有用到的方法，都硬编码写成JS然后插入到WKWebView展示的页面中。

如下：

```
function 方法名(参数…) {
  var result = window.prompt(方法名, 参数);
  return result;
}
```

但照如上实现的话，因为项目中用了20+个方法，需要重复写入20+个上述方法。并且旧方案中，有些方法传入的参数是不一定的，有可能传入2个参数、有可能传入4个参数。所以要考虑不同数量的参数怎么解决。

直到后面有想到，前端组之前实现过一个嵌套frame的方法转换。因为旧项目中frame内的H5代码调用原生挂载的方法是调用不到的，因为不会传递给所有的frame。

后面前端组加了一个方法映射，frame内部调用的方法，会映射到外部的H5中，达到响应H5的功能。

所以参考了方法映射的功能，前端组的实现如下：

```
<script>
  // 判断是否为ios设备
  var iosApiList = ["method1", "method2", "method3", "method4", "method5", "method6", "method7"];
  var u = navigator.userAgent;
  var isIOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/);
  if (window.parent && isIOS) {
    iosApiList.forEach(function(v) {
      window[v] = window.parent[v]
      // window[v] = function() {
      //  window.parent[v](...arguments)
      // }
    })
  }
</script>
```

其中关键为window[v] = window.parent[v]; 循环将方法映射

以及  window.parent [v] (…arguments) 将所有参数传递到外层parent[v]中。

经查询资料，arguments是JS函数中一个含有所有参数的对象，类似一个数组。

然后针对以上得到的信息，进行了原生插入替换方案，如下：

```
//H5交互方法替换
var iosApiList = ["method1", "method2", "method3", "method4", "method5", "method6", "method7"];

iosApiList.forEach (
  function (v) {
    window[v] = function () {
      var s = "";
      if (typeof(arguments) != "underfined") {
        for (var i = 0; i < arguments.length; i++) {
          s = s + arguments[i];
          s = s + '#$#@';
        }
      }
      var j = window.prompt('tshH5_' + v, s);
      if (j == "true##") {
        return true;
      } else if (j == "false##") {
        return false;
      } else {
        return j;
      }
    }
  }
)
```

对部分内容做说明。

window[v] = function () {    是将数组中的方法，映射成自定义的方法。

typeof(arguments) != "underfined"是判断参数是否为空

s = s + arguments[i];   是拼接参数，s = s + '#$#@';，采用一个特定的字符串进行拼接，以便后续原生可以转换成数组。

var j = window.prompt('tshH5_' + v, s);   在方法名前加入特定的字符串进行拼接，以便原生可以区分出是转换过的方法。

j == "true##"和return true;  后半部分的判断是判断是否需要将返回值转成不是字符串的类型。因为prompt返回的结果是字符串，加入了特定字符串区分是否需要转成不同的类型。

原生的代码监听实现如下：

```
//JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    if ([prompt hasPrefix:@"tshH5_"]) {
        DDLogDebug(@"=============key:%@,  params:%@",prompt ,defaultText);
        NSArray *paramArray;
        if ([defaultText isEqualToString:@""] || defaultText == nil) {
            paramArray = @[];
        } else {
            if ([defaultText hasSuffix:@"#$#@"]) {
                defaultText = [defaultText substringToIndex:defaultText.length - 4];
            }
            paramArray = [defaultText componentsSeparatedByString:@"#$#@"];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
        		//传递参数到对应的方法内，原项目中具体实现的方法不变。
            [self mountJSMethodWithKey:[prompt substringFromIndex:6] params:paramArray handle:completionHandler];
        });
    }
}
```

监听prompt的开头是不是tshH5_，如果是则执行之前的对应的方法即可。

需要确保，不管原先的方法有没有返回值，都需要调用completionHandler(@””)，返回回调，以免崩溃。

最后针对JS的打印也需要转换一下，因为原先项目中打印需要加入到日志中，所以打印的映射修改如下：

```
//打印方法替换
console.log = (
  function (oriLogFunc) {
    return function (str) {
      window.prompt('tshH5_' + 'consoleLog', str);
      oriLogFunc.call(console, str);
    }
  }
)(console.log);
//警告方法替换
console.warn = (
  function (oriWarnLogFunc) {
    return function (str) {
      window.prompt('tshH5_' + 'consoleWarnLog', str);
      oriWarnLogFunc.call(console, str);
    }
  }
)(console.warn);
//错误方法替换
console.error = (
  function (oriErrorLogFunc) {
    return function (str) {
      window.prompt('tshH5_' + 'consoleErrorLog', str);
      oriErrorLogFunc.call(console, str);
    }
  }
)(console.error);
```

这样实现之后，原本H5项目中的代码可以不进行修改。只需要原生将UIWebView的逻辑换成WKWebview来实现，并且插入上述JS内容即可。