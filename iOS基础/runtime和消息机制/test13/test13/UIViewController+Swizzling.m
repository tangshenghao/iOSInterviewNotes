//
//  UIViewController+Swizzling.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/29.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "UIViewController+Swizzling.h"

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@implementation UIViewController (Swizzling)

+ (void)load {
    [super load];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        // 原方法名 和 要替换的方法名
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(swizzle_viewDidAppear:);
        
        //获取方法
        
        
        
    });
}


- (void)swizzle_viewDidAppear:(BOOL)animated {
    NSLog(@"执行了交换的方法");
    
    //此处调用swizzle_viewDidAppear不会造成递归调用，因为已经交换过，执行的是原来的方法
    [self swizzle_viewDidAppear:animated];
    
}


@end
