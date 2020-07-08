//
//  TestView.m
//  test18
//
//  Created by 胜皓唐 on 2020/7/8.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestView.h"

@implementation TestView

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    return nil;
//}

//扩大点击范围
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds =	self.bounds;
    bounds = CGRectInset(bounds, -20, -20);
    return CGRectContainsPoint(bounds, point);
}


@end
