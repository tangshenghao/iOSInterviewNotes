//
//  ViewController.m
//  test14
//
//  Created by 胜皓唐 on 2020/7/1.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
            NSLog(@"执行计时器");
        }];
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        CFRunLoopRef runloopRef = [runloop getCFRunLoop];
        [runloop run];
        CFRunLoopRef runloopRef1 = [runloop getCFRunLoop];
        NSLog(@"-");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        CFRunLoopRef runloopRef = [runloop getCFRunLoop];
        //让其run时，此时没有modeitem，即使执行了也没有东西执行会直接进入休眠状态
        [runloop run];
        CFRunLoopRef runloopRef2 = [runloop getCFRunLoop];
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
            NSLog(@"执行计时器2");
        }];
        CFRunLoopRef runloopRef3 = [runloop getCFRunLoop];
        //此时有modeitem在里面了，但是此时时休眠的状态，不会主动唤醒。此时在run一下就会执行
        NSLog(@"-");
        
    });
    
}


@end
