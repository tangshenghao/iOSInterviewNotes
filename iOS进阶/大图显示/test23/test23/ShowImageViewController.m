//
//  ShowImageViewController.m
//  test23
//
//  Created by 胜皓唐 on 2020/9/17.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ShowImageViewController.h"
#import "UIImageView+largeImage.h"
#import "LargeImageView.h"

@interface ShowImageViewController ()


@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ShowImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 方式1 直接赋值 用模拟器内存提升不明显 但是用真机会内存增大
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    [self.imageView setImage:[UIImage imageNamed:@"1.jpg"]];
//    [self.view addSubview:self.imageView];
    
    // 方式2 官方分解加载 内存先高 退出后恢复
//    [self.imageView setLargeImage:[UIImage imageNamed:@"1.jpg"]];
    
    // 方式3 CATiledLayer
    LargeImageView *largeImageView = [[LargeImageView alloc] initWithFrame:self.view.bounds];
    [largeImageView setImageName:@"1.jpg"];
    [self.view addSubview:largeImageView];
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
