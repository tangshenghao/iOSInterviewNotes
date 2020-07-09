//
//  PThreadViewController.m
//  test19
//
//  Created by 胜皓唐 on 2020/7/9.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "PThreadViewController.h"
#import <pthread.h>

@interface PThreadViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PThreadViewController

void *run(void *param) {
    NSLog(@"pthread - %@", [NSThread currentThread]);
    
    return NULL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.imageView = [[UIImageView alloc] init];
    [self.imageView setFrame:CGRectMake(30, 100, 100, 100)];
    [self.view addSubview:self.imageView];
    
    
    
    // pthread方式
//    [self pthreadRun];
    // NSThread方式
    [self nsthreadRun];
    // NSThread 线程通讯
    [self dosomeAsyncAction];
}

- (void)pthreadRun {
    // 创建线程 定义pthread_t变量
    pthread_t thread;
    // 开启线程 执行任务
    pthread_create(&thread, NULL, run, NULL);
    // 设置子线程的状态设置为detached，该线程运行结束后会自动释放所有资源
    pthread_detach(thread);
}

- (void)nsthreadRun {
    // 创建线程 - 关联方法
//    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(nsthreadRunAction) object:nil];
//    // 启动线程
//    [thread start];
    
    // 创建线程后自动执行方法
    [NSThread detachNewThreadSelector:@selector(nsthreadRunAction) toTarget:self withObject:nil];
    
}

- (void)nsthreadRunAction {
    NSLog(@"NSThread - %@", [NSThread currentThread]);
}

- (void)dosomeAsyncAction {
    [NSThread detachNewThreadSelector:@selector(donwlaodImage) toTarget:self withObject:nil];
}

- (void)donwlaodImage {
    
    NSURL *imageUrl = [NSURL URLWithString:@"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=1764734306,495704103&fm=26&gp=0.jpg"];
    
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    
    UIImage *image = [UIImage imageWithData:imageData];
    
    [self performSelectorOnMainThread:@selector(renderImageView:) withObject:image waitUntilDone:NO];
    
}

- (void)renderImageView:(UIImage *)image {
    NSLog(@"renderImageView - %@", [NSThread currentThread]);
    
    self.imageView.image = image;
}

- (void)dealloc {
    NSLog(@"pthread VC 销毁");
}

@end
