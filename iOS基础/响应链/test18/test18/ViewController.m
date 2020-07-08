//
//  ViewController.m
//  test18
//
//  Created by 胜皓唐 on 2020/7/8.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestView.h"
#import "TestView2.h"
#import "TestView3.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet TestView *testView1;
@property (weak, nonatomic) IBOutlet TestView2 *testView2;
@property (weak, nonatomic) IBOutlet TestView3 *testView3;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.testView1.userInteractionEnabled = NO;
}



@end
