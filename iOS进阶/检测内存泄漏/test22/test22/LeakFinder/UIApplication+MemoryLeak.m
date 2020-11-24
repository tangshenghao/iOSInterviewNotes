//
//  UIApplication+MemoryLeak.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "UIApplication+MemoryLeak.h"
#import <objc/runtime.h>
#import "NSObject+MemoryLeak.h"

extern const void *const kLatestSenderKey;

@implementation UIApplication (MemoryLeak)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(sendAction:to:from:forEvent:) withSEL:@selector(swizzled_sendAction:to:from:forEvent:)];
    });
}

// 记录最后一个发送事件的类
- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    objc_setAssociatedObject(self, kLatestSenderKey, @((uintptr_t)sender), OBJC_ASSOCIATION_RETAIN);

    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
}

@end
