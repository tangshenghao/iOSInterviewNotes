//
//  ViewController.m
//  OffScreenRender
//
//  Created by 胜皓唐 on 2020/9/2.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 正常单个UIImageView设置图片和圆角不会有离屏渲染 iOS9对UIImageView做了优化
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    imageView.image = [UIImage imageNamed:@"test"];
    imageView.layer.cornerRadius = 30.f;
    imageView.layer.masksToBounds = YES;
    // 如果加上背景色、边框、有图像内容的图层 就会产生离屏渲染
//    imageView.layer.borderWidth = 3.f;
//    imageView.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:imageView];
    
    //加上子视图会产生离屏渲染
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
//    imageView2.image = [UIImage imageNamed:@"test"];
    imageView2.backgroundColor = [UIColor blackColor];
    imageView2.layer.cornerRadius = 30.f;
    imageView2.layer.masksToBounds = YES;
    [imageView addSubview:imageView2];
    
    
    // 给View的content设置图像内容会造成离屏渲染
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 250, 100, 100)];
    view.backgroundColor = [UIColor redColor];
    view.layer.cornerRadius = 30.f;
    view.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"test"].CGImage);
    view.clipsToBounds = YES;
    [self.view addSubview:view];
    
    
    
}


@end
