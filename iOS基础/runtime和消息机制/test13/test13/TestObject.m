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
//+ (BOOL)resolveInstanceMethod:(SEL)sel {
//    
//    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
//        NSLog(@"添加resolveInstanceMethod转发方法");
//        
//        //实例方法需要添加到类中
//        class_addMethod([self class], sel, (IMP)dynamicMethodIMP, "v@:");
//        
//        return YES;
//    }
//    
//    return [super resolveInstanceMethod:sel];
//}
//
//+ (BOOL)resolveClassMethod:(SEL)sel {
//    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
//        NSLog(@"添加resolveClassMethod转发方法");
//        
//        //类方法需要插入到元类中
//        Class metaClass = objc_getMetaClass([NSStringFromClass([self class]) UTF8String]);
//        
//        class_addMethod(metaClass, sel, (IMP)dynamicMethodIMP, "v@:");
//        
//        return YES;
//    }
//    
//    return [super resolveInstanceMethod:sel];
//}

// 消息转发第二步 Fast forwarding 快速转发阶段
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    if ([NSStringFromSelector(aSelector) isEqualToString:@"logTest"]) {
//        Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
//        //返回实例对象
//        return [[TestObjectTwo alloc] init];
//    }
//
//    return [super forwardingTargetForSelector:aSelector];
//}
//
//+ (id)forwardingTargetForSelector:(SEL)aSelector {
//    if ([NSStringFromSelector(aSelector) isEqualToString:@"logTest"]) {
//        Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
//        //返回类对象
//        return TestObjectTwo;
//    }
//
//    return [super forwardingTargetForSelector:aSelector];
//}

// 消息转发第三步 Normal forwarding 常规转发阶段
// 3.1 先创建签名标签
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //写法例子
    //例子"v@:@"
    //v@:@ v 返回值类型void;@ id类型,执行sel的对象;: SEL;@ 参数
    //例子"@@:"
    //@ 返回值类型id;@ id类型,执行sel的对象;: SEL
    
    if ([super methodSignatureForSelector:aSelector] == nil) {
        NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"v@:"];
        return sign;
    }
    
    return [super methodSignatureForSelector:aSelector];
}

// 执行消息转发调用
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    //创建备用对象
    Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
    id testObjectTwo = [[TestObjectTwo alloc] init];
    SEL sel = anInvocation.selector;
    
    if ([TestObjectTwo respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:testObjectTwo];
    } else {
        [self doesNotRecognizeSelector:sel];
    }
}


+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //写法例子
    //例子"v@:@"
    //v@:@ v 返回值类型void;@ id类型,执行sel的对象;: SEL;@ 参数
    //例子"@@:"
    //@ 返回值类型id;@ id类型,执行sel的对象;: SEL
    
    if ([super methodSignatureForSelector:aSelector] == nil) {
        NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"v@:"];
        return sign;
    }
    
    return [super methodSignatureForSelector:aSelector];
}

// 执行消息转发调用
+ (void)forwardInvocation:(NSInvocation *)anInvocation {
    //创建备用对象
    Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
    SEL sel = anInvocation.selector;
    
    if ([TestObjectTwo respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:TestObjectTwo];
    } else {
        [self doesNotRecognizeSelector:sel];
    }
}


@end
