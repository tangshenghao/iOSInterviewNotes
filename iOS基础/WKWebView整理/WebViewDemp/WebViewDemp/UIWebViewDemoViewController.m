//
//  UIWebViewDemoViewController.m
//  WebViewDemp
//
//  Created by 胜皓唐 on 2020/6/15.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "UIWebViewDemoViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@protocol OCJSExport <JSExport>

JSExportAs(jSToOC3, - (NSString *)jSToOC3WithParam:(NSString *)param type:(NSString *)type);

@end

@interface UIWebViewDemoViewController () <UIWebViewDelegate, OCJSExport>

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation UIWebViewDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    [self loadWebView];
    
    [self configRightItem];
    
    [self mountJSMethod];
}

- (void)dealloc {
    NSLog(@"释放");
}

- (void)loadWebView {
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSURL *fileURL = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileURL];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    [self.webView loadRequest:request];
}

- (void)configRightItem {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"原生事件" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClicked)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

//原生发送给JS
- (void)rightButtonClicked {
    //stringByEvaluatingJavaScriptFromString 方式
//    NSString *ocToJSStr = @"ocToJS('ocDoSomeThing', 'someParams')";
//    [self.webView stringByEvaluatingJavaScriptFromString:ocToJSStr];
    //JavaScriptCore 方式
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //JavaScriptCore 方式 - 中的 evaluateScript 方式
//    [context evaluateScript:[NSString stringWithFormat:@"ocToJS('ocDoSomeThing2', 'someParams')"]];
    //JavaScriptCore 方式 - 中的 callWithArguments 方式
    [context[@"ocToJS"] callWithArguments:@[@"ocDoSomeThing3", @"someParams"]];
}

//JS发送给原生 - 通过JavaScriptCore方法
- (void)mountJSMethod {
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
}

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


#pragma mark - delegate
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
- (void)webViewDidStartLoad:(UIWebView *)webView {
    //开始加载
    NSLog(@"uiwebview DidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //加载成功
    self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    //获取JS代码的执行环境/上下文/作用域
    JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //在context注册OCJSBridge对象为self
    //通过JSExport协议 以下写法会有循环引用 解决办法是用另外一个类来实现代理
    context[@"OCJSBridge"] = self;
    
    NSLog(@"uiwebview DidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //加载失败
    NSLog(@"webview didFailLoadWithError:%@", error);
}

    


@end
