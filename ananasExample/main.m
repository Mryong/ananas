//
//  main.m
//  ananasExample
//
//  Created by jerry.yong on 2017/10/31.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "ANC.h"

#include <stdlib.h>
#include <stdio.h>

int main(int argc, char * argv[]) {
	extern FILE *yyin;
	extern int yyparse(void);
	char *path = "/Users/yongpengliang/Documents/ananas/ananas/compiler/test.ana";
	yyin = fopen(path, "r");
	ANCompileUtil *compileUtil_backup = anc_get_current_compile_util();
	ANCompileUtil *compileUtil = [[ANCompileUtil alloc] init];
	anc_set_current_compile_util(compileUtil);
	if(yyparse()){
		printf("编译错误");
	}
	anc_set_current_compile_util(compileUtil_backup);
	
	
	
	
//	@autoreleasepool {
//	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//	}
}
