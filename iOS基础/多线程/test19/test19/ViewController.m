//
//  ViewController.m
//  test19
//
//  Created by 胜皓唐 on 2020/7/9.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "PThreadViewController.h"
#import "NSOperationViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)pushPthreadVC:(id)sender {
    
    PThreadViewController *pthreadVC = [[PThreadViewController alloc] init];
    [self.navigationController pushViewController:pthreadVC animated:YES];
    
}

- (IBAction)pushOperationVC:(id)sender {
    NSOperationViewController *operationVC = [[NSOperationViewController alloc] init];
    [self.navigationController pushViewController:operationVC animated:YES];
}

- (IBAction)pushGCDVC:(id)sender {
    
    
}



@end
