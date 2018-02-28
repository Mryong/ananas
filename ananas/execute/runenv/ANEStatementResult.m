//
//  ANEStatementResult.m
//  ananasExample
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ANEStatementResult.h"


@implementation ANEStatementResult

+ (instancetype)normalResult{
	ANEStatementResult *res = [ANEStatementResult new];
	res.type = ANEStatementResultTypeNormal;
	return res;
}

+ (instancetype)returnResult{
	ANEStatementResult *res = [ANEStatementResult new];
	res.type = ANEStatementResultTypeReturn;
	return res;
}

+ (instancetype)breakResult{
	ANEStatementResult *res = [ANEStatementResult new];
	res.type = ANEStatementResultTypeBreak;
	return res;
}

+ (instancetype)continueResult{
	ANEStatementResult *res = [ANEStatementResult new];
	res.type = ANEStatementResultTypeContinue;
	return res;
}

@end

