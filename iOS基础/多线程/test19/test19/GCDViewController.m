//
//  GCDViewController.m
//  test19
//
//  Created by 胜皓唐 on 2020/7/10.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "GCDViewController.h"

@interface GCDViewController ()

// 可以将dispatch_once_t作为属性，然后赋值0的时候，可以再次执行gcd的once
@property (nonatomic, assign) dispatch_once_t onceToken;

@property (nonatomic, assign) int ticketCount;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation GCDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button1 setTitle:@"GCD 直接Run 操作" forState:UIControlStateNormal];
    [button1 setFrame:CGRectMake(30, 90, 200, 50)];
    [button1 addTarget:self action:@selector(gcdRun) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 setTitle:@"GCD 线程间操作 操作" forState:UIControlStateNormal];
    [button2 setFrame:CGRectMake(30, 165, 200, 50)];
    [button2 addTarget:self action:@selector(gcdCommunity) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button3 setTitle:@"GCD 栏栅 操作" forState:UIControlStateNormal];
    [button3 setFrame:CGRectMake(30, 240, 200, 50)];
    [button3 addTarget:self action:@selector(gcdBarrir) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button4 setTitle:@"GCD 延时 操作" forState:UIControlStateNormal];
    [button4 setFrame:CGRectMake(30, 310, 200, 50)];
    [button4 addTarget:self action:@selector(gcdDelay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button4];
    
    UIButton *button5 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button5 setTitle:@"GCD 一次性 操作" forState:UIControlStateNormal];
    [button5 setFrame:CGRectMake(30, 380, 200, 50)];
    [button5 addTarget:self action:@selector(gcdOnce) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button5];
    
    UIButton *button6 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button6 setTitle:@"GCD 快速迭代 操作" forState:UIControlStateNormal];
    [button6 setFrame:CGRectMake(30, 450, 200, 50)];
    [button6 addTarget:self action:@selector(gcdFastApply) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button6];
    
    UIButton *button7 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button7 setTitle:@"GCD Group 操作" forState:UIControlStateNormal];
    [button7 setFrame:CGRectMake(30, 525, 200, 50)];
    [button7 addTarget:self action:@selector(gcdGroup) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button7];
    
    UIButton *button8 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button8 setTitle:@"GCD 信号量 操作" forState:UIControlStateNormal];
    [button8 setFrame:CGRectMake(30, 600, 200, 50)];
    [button8 addTarget:self action:@selector(gcdSemaphore) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button8];
}

- (void)gcdRun {
    
    NSLog(@"0----- current Thread :%@", [NSThread currentThread]);
//    // 同步执行加并发队列 没有开启新线程 串行进行
//    dispatch_queue_t queue = dispatch_queue_create("com.tsh.concurrent1", DISPATCH_QUEUE_CONCURRENT);
//
//    dispatch_sync(queue, ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//    });
    
//    // 异步执行加并发队列 开启新线程 并发进行
//    dispatch_queue_t queue = dispatch_queue_create("com.tsh.concurrent1", DISPATCH_QUEUE_CONCURRENT);
//
//    dispatch_async(queue, ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_async(queue, ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_async(queue, ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//    });
    
//    // 同步执行加串行队列 不开启新线程 顺序进行
//    dispatch_queue_t queue = dispatch_queue_create("com.tsh.concurrent1", DISPATCH_QUEUE_SERIAL);
//
//    dispatch_sync(queue, ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//    });
    
//    // 异步执行加串行队列 开启1个线程 顺序进行
//    dispatch_queue_t queue = dispatch_queue_create("com.tsh.concurrent1", DISPATCH_QUEUE_SERIAL);
//
//    dispatch_async(queue, ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_async(queue, ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_async(queue, ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//    });
    
//    // 同步执行加主队列 在主线程环境下 卡死
//    dispatch_queue_t queue = dispatch_get_main_queue();
//
//    dispatch_sync(queue, ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//    });
    
//    // 同步执行加主队列 在子线程环境下 顺序执行
//    dispatch_queue_t queue = dispatch_get_main_queue();
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        dispatch_sync(queue, ^{
//            NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//        });
//
//        dispatch_sync(queue, ^{
//            NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//        });
//
//        dispatch_sync(queue, ^{
//            NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//        });
//    });
    
    // 异步执行加主队列 不开启线程 顺序执行
    dispatch_queue_t queue = dispatch_get_main_queue();

    
    dispatch_async(queue, ^{
        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
    });
    
    NSLog(@"E----- end Run");
}

- (void)gcdCommunity {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        //耗时操作放到子线程
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1---%@", [NSThread currentThread]);
        }
        
        //结束后回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"2---%@", [NSThread currentThread]);
        });
        
    });
}

- (void)gcdBarrir {
    
    dispatch_queue_t queue = dispatch_queue_create("com.tsh.concurrent1", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"barrier----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"4----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"5----- current Thread :%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"6----- current Thread :%@", [NSThread currentThread]);
    });
    
    
    
}

- (void)gcdDelay {
    NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
    });
}

- (void)gcdOnce {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
    });
}

- (void)gcdFastApply {
    
    NSLog(@"apply begin");
    dispatch_apply(6, dispatch_get_global_queue(0, 0), ^(size_t index) {
        NSLog(@"%zu----- current Thread :%@",index, [NSThread currentThread]);
    });
    NSLog(@"apply end");
}

- (void)gcdGroup {
    NSLog(@"group begin thread:%@", [NSThread currentThread]);
    dispatch_group_t group = dispatch_group_create();
    
    
    
//    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//    });
//
//    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
//        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
//    });
    
    //使用Notify
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
//        NSLog(@"group end");
//    });
    
    //使用wait
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
//    NSLog(@"group end");
    
    
    //使用enter 和 leave
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"2----- current Thread :%@", [NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"3----- current Thread :%@", [NSThread currentThread]);
        NSLog(@"group end");
    });
    
}

- (void)gcdSemaphore {
    
    // 异步转同步
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//
//    __block int someValue = 0;
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSLog(@"1----- current Thread :%@", [NSThread currentThread]);
//        someValue = 100;
//        dispatch_semaphore_signal(semaphore);
//    });
//
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//
//    NSLog(@"value = %d", someValue);
    
    
    // 线程加锁
    self.semaphore = dispatch_semaphore_create(1);
    
    dispatch_queue_t queue1 = dispatch_queue_create("com.tsh.serial1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("com.tsh.serial2", DISPATCH_QUEUE_SERIAL);
    
    self.ticketCount = 50;
    
    dispatch_async(queue1, ^{
        [self buyTicket];
    });
    
    dispatch_async(queue2, ^{
        [self buyTicket];
    });
    
}

- (void)buyTicket {
    while (1) {
        
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        
        if (self.ticketCount > 0) {
            self.ticketCount--;
            [NSThread sleepForTimeInterval:0.1
             ];
            NSLog(@"剩余票数为：%d  thread:%@", self.ticketCount, [NSThread currentThread]);
        }
        
        dispatch_semaphore_signal(self.semaphore);
        
        if (self.ticketCount <= 0) {
            NSLog(@"票卖完了");
            break;
        }
    }
}

- (void)dealloc {
    NSLog(@"GCDVC 销毁");
}
@end
