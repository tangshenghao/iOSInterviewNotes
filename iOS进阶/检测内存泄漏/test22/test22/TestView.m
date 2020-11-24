//
//  TestView.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "TestView.h"

@implementation TestView

+ (instancetype)shareInstance {
    static TestView *testView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testView = [[TestView alloc] init];
    });
    return testView;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
