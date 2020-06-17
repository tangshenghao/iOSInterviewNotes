//
//  WKWebViewDemoViewController.m
//  WebViewDemp
//
//  Created by 胜皓唐 on 2020/6/15.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "WKWebViewDemoViewController.h"
#import <WebKit/WebKit.h>

@interface WKWebViewDemoViewController () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation WKWebViewDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    [self loadWebView];
    
    [self configRightItem];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"JSToOC2"];
}

- (void)dealloc {
    NSLog(@"释放");
}

- (void)loadWebView {
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"html"];
    NSURL *fileURL = [NSURL fileURLWithPath:urlStr];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileURL];
    
    
    // 加载方法交换JS
    NSString *jsFilePath = [[NSBundle mainBundle] pathForResource:@"H5MethodTransform" ofType:@"js"];
    NSData *jsData = [NSData dataWithContentsOfFile:jsFilePath];
    NSString *jsString = [[NSString alloc] initWithData:jsData encoding:NSUTF8StringEncoding];
    WKUserScript *jsEventScript = [[WKUserScript alloc] initWithSource:jsString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    
    WKUserContentController *userConnectController = [[WKUserContentController alloc] init];
    [userConnectController addScriptMessageHandler:self name:@"JSToOC2"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.selectionGranularity = WKSelectionGranularityDynamic;
    config.allowsInlineMediaPlayback = YES;
    config.userContentController = userConnectController;
    [config.userContentController addUserScript:jsEventScript];
    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    config.preferences = preferences;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:request];
    
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
}

- (void)configRightItem {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"原生事件" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClicked)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

//原生发送给JS
- (void)rightButtonClicked {
    //stringByEvaluatingJavaScriptFromString 方式
    NSString *ocToJSStr = @"ocToJS('ocDoSomeThing', 'someParams')";
    [self.webView evaluateJavaScript:ocToJSStr completionHandler:^(id _Nullable params, NSError * _Nullable error) {
        NSLog(@"发送回调 %@ --- error：%@", params, error);
    }];
}


#pragma mark - WKNavigationDelegate

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


//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction preferences:(WKWebpagePreferences *)preferences decisionHandler:(void (^)(WKNavigationActionPolicy, WKWebpagePreferences *))decisionHandler  API_AVAILABLE(ios(13.0)) {
//    //iOS13之后出现的是否跳转处理
//    NSLog(@"wk=======decidePolicyForNavigationAction=preferences");
//    decisionHandler(WKNavigationActionPolicyAllow, preferences);
//}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    //收到响应后是否跳转
    NSLog(@"wk=======decidePolicyForNavigationResponse = ");
    decisionHandler(WKNavigationResponsePolicyAllow);
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"wk=======didStartProvisionalNavigation==页面开始调用");
}


- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"wk=======didReceiveServerRedirectForProvisionalNavigation==服务器跳转请求之后调用");
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"wk=======didFailProvisionalNavigation==加载失败：%@", error);
}


- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"wk=======didCommitNavigation==执行提交");
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"wk=======didFinishNavigation==加载完成");
    [webView evaluateJavaScript:@"document.title" completionHandler:^(NSString *title, NSError *error) {
        self.title = title;
    }];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"wk=======didFailNavigation==导航失败");
}


//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
//    //证书验证
//}


- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    //进程崩溃 //需要重新刷新页面
    NSLog(@"wk=======webViewWebContentProcessDidTerminate==进程崩溃");
}

#pragma mark - WKScriptMessageHandler
//WKScriptMessageHandler方式
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"JSToOC2"]) {
        NSLog(@" 接收到了JS传递过来的事件，参数1 = %@，参数2 = %@ ",message.name, message.body);
    }
}

#pragma mark - WKUIDelegate
- (void)webViewDidClose:(WKWebView *)webView {
    //关闭webView
    NSLog(@"关闭webView");
}

//Prompt方式进行传递
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    NSLog(@" 接收到了JS传递过来的prompt事件，参数1 = %@，参数2 = %@ ",prompt ,defaultText);
    completionHandler(@"asdasd");
}


@end
