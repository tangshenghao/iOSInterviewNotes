//
//  ViewController.m
//  test20
//
//  Created by 胜皓唐 on 2020/7/13.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TSSpinLock.h"

@interface ViewController () {
    int count;
}

@property (atomic, strong) NSArray *array;

@property (nonatomic, strong) TSSpinLock *lock;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 使用atomic还是会线程不安全，只保证读写操作
//    self.lock = [[NSLock alloc] init];
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        for (int i = 0; i < 10000; i++) {
//            [self.lock lock];
//            if (i % 2 == 0) {
//                self.array = @[@"1", @"2", @"3"];
//            } else {
//                self.array = @[@"1"];
//            }
//            [self.lock unlock];
//            NSLog(@"Thread A : %@ , i = %d, current Thread = %@", self.array, i, [NSThread currentThread]);
//        }
//    });
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        for (int j = 0; j < 10000; j++) {
//            [self.lock lock];
//            if (self.array.count >= 2) {
//                NSLog(@"value = %@。current Thread = %@", [self.array objectAtIndex:1], [NSThread currentThread]);
//            }
//            [self.lock unlock];
//            NSLog(@"=%d", j);
//        }
//    });
//    count = 20;
//    [self testSynchronized];
    
    self.lock = [[TSSpinLock alloc] init];
    
    count = 100;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self test];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self test];
    });
    
    
}

- (void)test {
    while (1) {
        
        [self.lock lock];
        NSLog(@"====加锁");
        if (count > 0) {
            count--;
            [NSThread sleepForTimeInterval:0.5];
            NSLog(@"====剩余票数为：%d  thread:%@", count, [NSThread currentThread]);
        }
        NSLog(@"====解锁");
        [self.lock unlock];
        
        if (count <= 0) {
            NSLog(@"票卖完了");
            break;
        }
    }
}

- (void)testSynchronized {
    if (count > 0) {
        @synchronized (self) {
            count--;
            NSLog(@"count = %d", count);
            [self testSynchronized];
        }
    }
}


@end
