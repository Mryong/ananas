//
//  main.m
//  ananasExample
//
//  Created by jerry.yong on 2017/10/31.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ANCContext.h"


#include <stdlib.h>
#include <stdio.h>

int main(int argc, char * argv[]) {
	NSURL *scriptUrl = [NSURL URLWithString:@"file:///Users/yongpengliang/Documents/ananas/ananas/compiler/test.ana"];
	ANCContext *context = [[ANCContext alloc] init];
	[context evalAnanasScriptWithURL:scriptUrl];
	
//	@autoreleasepool {
//	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//	}
}
