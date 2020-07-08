//
//  UIView+Swizzing.m
//  test18
//
//  Created by 胜皓唐 on 2020/7/8.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "UIView+Swizzing.h"
#import <objc/runtime.h>

@implementation UIView (Swizzing)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL sel1 = @selector(hitTest:withEvent:);
        SEL sel2 = @selector(sw_hitTest:withEvent:);
        
        Method method1 = class_getInstanceMethod(self, sel1);
        Method method2 = class_getInstanceMethod(self, sel2);
        
        BOOL didAddMethod = class_addMethod(self, sel1, method_getImplementation(method2), method_getTypeEncoding(method2));
        
        if (didAddMethod) {
            class_replaceMethod(self, sel2, method_getImplementation(method1), method_getTypeEncoding(method1));
        } else {
            method_exchangeImplementations(method1, method2);
        }
        
        SEL sel3 = @selector(pointInside:withEvent:);
        SEL sel4 = @selector(sw_pointInside:withEvent:);

        Method method3 = class_getInstanceMethod(self, sel3);
        Method method4 = class_getInstanceMethod(self, sel4);

        BOOL didAddMethod2 = class_addMethod(self, sel3, method_getImplementation(method4), method_getTypeEncoding(method4));
        
        if (didAddMethod2) {
            class_replaceMethod(self, sel4, method_getImplementation(method3), method_getTypeEncoding(method3));
        } else {
            method_exchangeImplementations(method3, method4);
        }
        
        SEL sel5 = @selector(touchesBegan:withEvent:);
        SEL sel6 = @selector(sw_touchesBegan:withEvent:);

        Method method5 = class_getInstanceMethod(self, sel5);
        Method method6 = class_getInstanceMethod(self, sel6);

        BOOL didAddMethod3 = class_addMethod(self, sel5, method_getImplementation(method6), method_getTypeEncoding(method6));
        
        if (didAddMethod3) {
            class_replaceMethod(self, sel6, method_getImplementation(method5), method_getTypeEncoding(method5));
        } else {
            method_exchangeImplementations(method5, method6);
        }
    });
    
}


// 事件的传递
- (nullable UIView *)sw_hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
    NSLog(@" class:%@", [self class]);
    UIView *view = [self sw_hitTest:point withEvent:event];
//    NSLog(@"sw_hitTest2 class:%@ view:%@", [self class], [view class]);
    return view;
    
    
//    //自行实现hittest的操作
//    if (self.userInteractionEnabled == NO || self.alpha <= 0.01 || self.hidden == YES) {
//        return nil;
//    }
//    if (![self pointInside:point withEvent:event]) {
//        return nil;
//    }
//
//    NSInteger count = self.subviews.count;
//    UIView *retView = self;
//    for (NSInteger i = count - 1; i >= 0; i--) {
//        UIView *subView = self.subviews[i];
//        CGPoint subPoint = [self convertPoint:point toView:subView];
//        UIView *subRetView = [subView hitTest:subPoint withEvent:event];
//        if (subRetView) {
//            retView = subRetView;
//            break;
//        }
//    }
//    return retView;
}

- (BOOL)sw_pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
//    NSLog(@"sw_pointInside: class:%@", [self class]);
    return [self sw_pointInside:point withEvent:event];
}

// 事件的响应
- (void)sw_touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSLog(@"touchesBegan class: %@",self.class);
    
    [super touchesBegan:touches withEvent:event];
}
@end
