//
//  TestObjectTwo.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/28.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObjectTwo.h"

@implementation TestObjectTwo

// 消息转发第二步 Fast forwarding 快速转发阶段
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return [super forwardingTargetForSelector:aSelector];
}

@end
