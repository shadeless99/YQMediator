#import "YQViewControllerA.h"
#import "YQMediator.h"

@interface YQViewControllerA ()

@end

@implementation YQViewControllerA

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Controller A";
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"跳转到Controller B" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.layer.borderColor = [UIColor blackColor].CGColor;
    btn.layer.borderWidth = 1.f;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:20.f];
    [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    btn.bounds = CGRectMake(0, 0, 200, 40);
    btn.center = self.view.center;
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(jumpToBController) forControlEvents:UIControlEventTouchUpInside];
}
     
- (void)jumpToBController {
    NSURL *url1 = [NSURL URLWithString:@"YQScheme://YQViewControllerB"];
    UIViewController *vcB = [YQMediator viewControllerForURL:url1 withBlock:^(id  _Nullable returnVal, BOOL isConnect) {
        NSLog(@"%@",returnVal);
    }];
    [self.navigationController pushViewController:vcB animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
