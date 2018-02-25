//
//  ViewController.m
//  ananasExample
//
//  Created by jerry.yong on 2017/10/31.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	CGRect rect = CGRectMake(0, 0, 100, 100);
	UIView *view = [[UIView alloc] initWithFrame:rect];
	view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
	[self.view addSubview:view];
	
//	for (self.myv in arr) {
//		
//	}
	
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)btnDidClicked:(UIButton *)sender {
	[self testReplaceMethod:@"hello world"];
	NSLog(@"==========");
	
//	UIView *view = [[UIView alloc] init];
//	UIView *view = UIView.alloc().init();
	
}

- (void)testReplaceMethod:(NSString *)param{
	
}

@end
