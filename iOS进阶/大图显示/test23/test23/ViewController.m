//
//  ViewController.m
//  test23
//
//  Created by 胜皓唐 on 2020/9/17.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "ShowImageViewController.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(100, 200, 100, 100);
    [button setTitle:@"进入页面显示" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pushImageView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

- (void)pushImageView {
    ShowImageViewController *showImageViewController = [[ShowImageViewController alloc] init];
    [self.navigationController pushViewController:showImageViewController animated:YES];
}


@end
