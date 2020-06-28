//
//  TestObject.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/28.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject.h"
#import <objc/runtime.h>


void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@" dynamicMethodIMP ");
}

@implementation TestObject

// 消息转发第一步 拯救 Method Resolution 动态添加方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    
    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
        NSLog(@"添加resolveInstanceMethod转发方法");
        
        //实例方法需要添加到类中
        class_addMethod([self class], sel, (IMP)dynamicMethodIMP, "v@:");
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
        NSLog(@"添加resolveClassMethod转发方法");
        
        //类方法需要插入到元类中
        Class metaClass = objc_getMetaClass([NSStringFromClass([self class]) UTF8String]);
        
        class_addMethod(metaClass, sel, (IMP)dynamicMethodIMP, "v@:");
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}



@end
