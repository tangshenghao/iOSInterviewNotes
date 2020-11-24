//
//  UIView+MemoryLeak.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "UIView+MemoryLeak.h"
#import "NSObject+MemoryLeak.h"

@implementation UIView (MemoryLeak)

- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }
    // 递归检查所有子view
    [self willReleaseChildren:self.subviews];
    
    return YES;
}

@end
