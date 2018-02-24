//
//  ANANASStructDeclareTable.m
//  ananasExample
//
//  Created by jerry.yong on 2018/2/24.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ANANASStructDeclareTable.h"

@implementation ANANASStructDeclareTable{
	NSMutableDictionary<NSString *, ANCStructDeclare *> *_dic;
}

- (instancetype)init{
	if (self = [super init]) {
		_dic = [NSMutableDictionary dictionary];
	}
	return self;
}
+ (instancetype)shareInstance{
	static id _instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_instance = [[ANANASStructDeclareTable alloc] init];
	});
	return _instance;
}

- (void)addStructDeclare:(ANCStructDeclare *)structDeclare{
	_dic[structDeclare.name] = structDeclare;
}

- (ANCStructDeclare *)getStructDeclareWithName:(NSString *)name{
	return _dic[name];
}
@end
