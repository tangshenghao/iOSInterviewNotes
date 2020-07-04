//
//  main.m
//  test15
//
//  Created by 胜皓唐 on 2020/7/2.
//  Copyright © 2020 tsh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TestObject.h"

int s = 2;

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
        
//        __block int i = 2;
//        void (^Test10block)(void) = ^{
//            i = 3;
//            NSLog(@"i的值为:%d",i);
//        };
//        s = 5;
//        i = 4;
        __block NSObject *test1 = [[NSObject alloc] init];
        __block NSObject *test2 = [[NSObject alloc] init];
        __block NSObject *test3 = [[NSObject alloc] init];
        void (^Test10block)(void) = ^{

            NSLog(@"OC对象:%@-%@-%@",test1, test2, test3);
        };
        Test10block();
        
        
        TestObject *test = [[TestObject alloc] init];
        __weak typeof(test) weakTest = test;
        test.testBlock = ^{
            __strong typeof(weakTest) strongTest = weakTest;
            NSLog(@"调用了对象:%@",weakTest);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"delay调用了对象:%@",strongTest);
            });
        };
        test.testBlock();
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
