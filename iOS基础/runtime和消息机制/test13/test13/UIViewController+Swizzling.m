//
//  UIViewController+Swizzling.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/29.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "UIViewController+Swizzling.h"

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
        Method oriMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        if (!class || !oriMethod || !swizzledMethod) {
            return;
        }
        
        //多加一层判断，如果添加成功，表示该方法不存在于本类，而是在父类中，不能交换父类的方法，否则父类的对象调用该方法时会崩溃，如果添加失败说明存在于本类中
        BOOL canAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (canAddMethod) {
            //添加成功后，将原有的实现替换到swizzledMethod上，实现方法的交换而不影响父类的方法实现
            class_replaceMethod(class, swizzledSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
        } else {
            // 说明在本类中，交换方法的实现
            method_exchangeImplementations(oriMethod, swizzledMethod);
        }
        
    });
}


- (void)swizzle_viewDidAppear:(BOOL)animated {
    NSLog(@"执行了交换的方法");
    //此处调用swizzle_viewDidAppear不会造成递归调用，因为已经交换过，执行的是原来的方法
    [self swizzle_viewDidAppear:animated];
}


@end
