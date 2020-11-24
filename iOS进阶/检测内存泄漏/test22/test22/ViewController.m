//
//  ViewController.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "ViewController.h"
#import "TwoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)tapAction:(id)sender {
    
    TwoViewController *twoVC = [[TwoViewController alloc] init];
    [self presentViewController:twoVC animated:YES completion:nil];
    
}

@end
