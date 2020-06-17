//
//  ViewController.m
//  WebViewDemp
//
//  Created by 胜皓唐 on 2020/6/15.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "UIWebViewDemoViewController.h"
#import "WKWebViewDemoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"WebView";
}

- (IBAction)goToUIWebView:(id)sender {
    UIWebViewDemoViewController *webviewDemoVC = [[UIWebViewDemoViewController alloc] init];
    [self.navigationController pushViewController:webviewDemoVC animated:YES];
}

- (IBAction)goToWKWebView:(id)sender {
    WKWebViewDemoViewController *webviewDemoVC = [[WKWebViewDemoViewController alloc] init];
    [self.navigationController pushViewController:webviewDemoVC animated:YES];
}


@end
