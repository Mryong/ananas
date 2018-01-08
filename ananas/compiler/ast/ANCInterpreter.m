//
//  ANCTranslationUtil.m
//  ananasExample
//
//  Created by jerry.yong on 2017/11/23.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCInterpreter.h"
#import "ANEEnvironment.h"

@implementation ANCInterpreter

- (instancetype)init{
	if (self = [super init]) {
		_currentLineNumber = 1;
		_stack = [[ANEStack alloc] init];
		_topScope = [[ANEScopeChain alloc] init];
	}
	return self;
}

- (NSMutableDictionary<NSString *,ANCClassDefinition *> *)classDefinitionDic{
	if (_classDefinitionDic == nil) {
		_classDefinitionDic = [NSMutableDictionary dictionary];
	}
	return _classDefinitionDic;
}


- (NSMutableDictionary<NSString *,ANCStructDeclare *> *)structDeclareDic{
	if (_structDeclareDic == nil) {
		_structDeclareDic = [NSMutableDictionary dictionary];
	}
	return _structDeclareDic;
}

- (NSMutableDictionary<Class, NSMutableDictionary<NSString *,ANCFunctionDefinition *> *> *)functionDefinitionDic{
	if (_functionDefinitionDic == nil) {
		_functionDefinitionDic = [NSMutableDictionary dictionary];
	}
	return _functionDefinitionDic;
}

- (NSMutableArray<ANCStatement *> *)topList{
	if (_topList == nil) {
		_topList = [NSMutableArray array];
	}
	return _topList;
}


- (void)compileSoruceWithURL:(NSURL *)url{
	NSError *error;
	NSString *source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		NSLog(@"%@",error);
		return;
	}
	[self compileSoruceWithString:source];
	
}

- (void)compileSoruceWithString:(NSString *)source{
	extern void nac_set_source_string(char const *source);
	nac_set_source_string([source UTF8String]);
	
	extern int yyparse(void);
	if (yyparse()) {
		NSLog(@"error! error! error!");
		return;
	}
	
}









@end
