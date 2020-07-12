//
//  NSOperationViewController.m
//  test19
//
//  Created by 胜皓唐 on 2020/7/9.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "NSOperationViewController.h"
#import "TSHOperation.h"

@interface NSOperationViewController ()

@property (nonatomic, strong) NSBlockOperation *op4;

@property (nonatomic, assign) int ticketCount;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation NSOperationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
//    [NSThread detachNewThreadSelector:@selector(operationRun) toTarget:self withObject:nil];
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button1 setTitle:@"Operation 直接Run 操作" forState:UIControlStateNormal];
    [button1 setFrame:CGRectMake(30, 90, 200, 50)];
    [button1 addTarget:self action:@selector(operationRun) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 setTitle:@"Operation 通过Queue 操作" forState:UIControlStateNormal];
    [button2 setFrame:CGRectMake(30, 165, 200, 50)];
    [button2 addTarget:self action:@selector(operationQueueRun) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button3 setTitle:@"Operation 依赖 操作" forState:UIControlStateNormal];
    [button3 setFrame:CGRectMake(30, 240, 200, 50)];
    [button3 addTarget:self action:@selector(operationDependeRun) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button4 setTitle:@"Operation 优先级拉高 操作" forState:UIControlStateNormal];
    [button4 setFrame:CGRectMake(30, 310, 200, 50)];
    [button4 addTarget:self action:@selector(operationPriorty) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button4];
    
    UIButton *button5 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button5 setTitle:@"Operation 线程间通讯 操作" forState:UIControlStateNormal];
    [button5 setFrame:CGRectMake(30, 380, 200, 50)];
    [button5 addTarget:self action:@selector(operationCommunity) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button5];
    
    
    UIButton *button6 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button6 setTitle:@"Operation 线程安全 操作" forState:UIControlStateNormal];
    [button6 setFrame:CGRectMake(30, 450, 200, 50)];
    [button6 addTarget:self action:@selector(operationThreadSafe) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button6];
    
}

- (void)operationRun {
    // NSInvocationOperation方式
//    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    
    // NSBlockOperation
//    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"1---%@", [NSThread currentThread]);
//        }
//    }];
//
//    [op addExecutionBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"2---%@", [NSThread currentThread]);
//        }
//    }];

//    [op addExecutionBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"3---%@", [NSThread currentThread]);
//        }
//    }];
//
//    [op addExecutionBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"4---%@", [NSThread currentThread]);
//        }
//    }];
    
    // NSOperation 自定义子类
    TSHOperation *op = [[TSHOperation alloc] init];
     
    [op start];
}

- (void)operationQueueRun {
    // 创建队列
    // 主队列
//    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    // 非主队列 同时包含了串行和并行
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    // 设置最大并发数 默认为-1 设为1为串行 大于1为并行
    queue.maxConcurrentOperationCount = 2;
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task2) object:nil];
//    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"3---%@", [NSThread currentThread]);
//        }
//    }];
//    [op3 addExecutionBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"4---%@", [NSThread currentThread]);
//        }
//    }];
//
//    self.op4 = [NSBlockOperation blockOperationWithBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"7---%@", [NSThread currentThread]);
//        }
//    }];
    
    [queue addOperation:op1];
    [queue addOperation:op2];
//    [queue addOperation:op3];
//
//
//    [queue addOperationWithBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"5---%@", [NSThread currentThread]);
//        }
//    }];
    
//
//    [queue addOperationWithBlock:^{
//        for (int i = 0; i < 2; i++) {
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"6---%@", [NSThread currentThread]);
//        }
//    }];
//
//    [queue addOperation:self.op4];
}

- (void)operationDependeRun {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task2) object:nil];
    
    //依赖完第一个操作结束后再进行
    [op1 addDependency:op2];
    
    [queue addOperation:op1];
    [queue addOperation:op2];
}

- (void)operationPriorty {
    [self.op4 setQueuePriority:NSOperationQueuePriorityVeryHigh];
}

- (void)task1 {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"1---%@", [NSThread currentThread]);
    }
}

- (void)task2 {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"2---%@", [NSThread currentThread]);
    }
}

- (void)operationCommunity {
    // 新建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    // 将操作添加到队列中
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1---%@", [NSThread currentThread]);
        }
        // 在主队列中执行操作
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            for (int i = 0; i < 2; i++) {
                [NSThread sleepForTimeInterval:2];
                NSLog(@"2---%@", [NSThread currentThread]);
            }
        }];
    }];
}


- (void)operationThreadSafe {
    self.lock = [[NSLock alloc] init];
    
    NSOperationQueue *queue1 = [[NSOperationQueue alloc] init];
    NSOperationQueue *queue2 = [[NSOperationQueue alloc] init];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(buyTicket) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(buyTicket) object:nil];
    self.ticketCount = 50;
    
    [queue1 addOperation:op1];
    [queue2 addOperation:op2];
}

- (void)buyTicket {
    while (1) {
        [self.lock lock];
        if (self.ticketCount > 0) {
            self.ticketCount--;
            [NSThread sleepForTimeInterval:0.1
             ];
            NSLog(@"剩余票数为：%d  thread:%@", self.ticketCount, [NSThread currentThread]);
        }
        [self.lock unlock];
        
        if (self.ticketCount <= 0) {
            NSLog(@"票卖完了");
            break;
        }
    }
}

- (void)dealloc {
    NSLog(@"NSOperation VC 销毁");
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
