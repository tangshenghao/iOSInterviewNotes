//
//  TwoViewController.m
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import "TwoViewController.h"
#import "TestView.h"

@interface TwoViewController ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, copy) NSString *testString;

@property (nonatomic, strong) UIViewController *vc;

@end

@implementation TwoViewController

- (void)dealloc {
    
    NSLog(@"dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testString = @"xxx";
    // Do any additional setup after loading the view.
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(testLog) userInfo:nil repeats:YES];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(30, 30, 100, 40);
    [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
//    self.vc = self;
    
    UIView *test1 = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    test1.backgroundColor = [UIColor grayColor];
    
    UIView *test2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    test1.backgroundColor = [UIColor grayColor];
    
    UIView *test3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    test1.backgroundColor = [UIColor grayColor];
    
    UIView *test4 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    test1.backgroundColor = [UIColor grayColor];
    
    UIView *test5 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    test1.backgroundColor = [UIColor grayColor];
    
    TestView *test6 = [TestView shareInstance];
    test6.frame = CGRectMake(0, 0, 100, 100);
//    test6.vc = self;
    
    [test1 addSubview:test2];
    [test2 addSubview:test3];
    [test3 addSubview:test4];
    [test4 addSubview:test5];
    [test5 addSubview:test6];
    [self.view addSubview:test1];
    
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)testLog {
    NSLog(@"1 - %@", self.testString);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
