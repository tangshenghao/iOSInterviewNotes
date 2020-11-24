//
//  LeakedObjectProxy.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "LeakedObjectProxy.h"
#import "NSObject+MemoryLeak.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static NSMutableSet *leakedObjectPtrs;
static __weak UIAlertController *alertController;

@interface LeakedObjectProxy()

@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSNumber *objectPtr;
@property (nonatomic, strong) NSArray *viewStack;

@end

@implementation LeakedObjectProxy

// 通过交集判断是否已经存在
+ (BOOL)isAnyObjectLeakedAtPtrs:(NSSet *)ptrs {
    
    NSAssert([NSThread isMainThread], @"Must be in main thread.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leakedObjectPtrs = [[NSMutableSet alloc] init];
    });
    
    if (!ptrs.count) {
        return NO;
    }
    if ([leakedObjectPtrs intersectsSet:ptrs]) {
        return YES;
    } else {
        return NO;
    }
}

// 添加对象到泄漏名单内
+ (void)addLeakedObject:(id)object {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");
    
    LeakedObjectProxy *proxy = [[LeakedObjectProxy alloc] init];
    proxy.object = object;
    proxy.objectPtr = @((uintptr_t)object);
    proxy.viewStack = [object viewStack];
    static const void *const kLeakedObjectProxyKey = &kLeakedObjectProxyKey;
    objc_setAssociatedObject(object, kLeakedObjectProxyKey, proxy, OBJC_ASSOCIATION_RETAIN);
    
    [leakedObjectPtrs addObject:proxy.objectPtr];
    
    // 弹窗提醒
    [self alertWithTitle:@"内存泄漏" message:[NSString stringWithFormat:@"%@", proxy.viewStack]];
    
}

// 弹窗显示
+ (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    dispatch_block_t block = ^() {
        UIAlertController *temp = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [temp addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:temp animated:YES completion:nil];
        alertController = temp;
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"程序捕捉到内存泄漏警告: title=%@, message=%@", title, message);
        if (alertController) {
            [alertController dismissViewControllerAnimated:NO completion:block];
        }
        else {
            block();
        }
    });
}

@end
