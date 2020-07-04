//
//  main.m
//  test15
//
//  Created by 胜皓唐 on 2020/7/2.
//  Copyright © 2020 tsh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

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
        NSObject *test1 = [[NSObject alloc] init];
        void (^Test10block)(void) = ^{

            NSLog(@"OC对象:%@",test1);
        };
        Test10block();
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
