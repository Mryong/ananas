//
//  ANCTranslationUtil.m
//  ananasExample
//
//  Created by jerry.yong on 2017/11/23.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCInterpreter.h"
#import "runenv.h"

static NSMutableDictionary<NSString *, ANEStack *> *_stacksDic;
static NSLock *_lock;

static ANEScopeChain *commonScope_;

@implementation ANCInterpreter

- (instancetype)init{
	if (self = [super init]) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			commonScope_ = [[ANEScopeChain alloc] init];
		});
		_stacksDic = [NSMutableDictionary dictionary];
		_lock = [[NSLock alloc] init];
		_currentLineNumber = 1;
		
		_topScope = [ANEScopeChain scopeChainWithNext:commonScope_];
		_commonScope = commonScope_;
	}
	return self;
}

- (ANEStack *)stack{
	NSString *currentThread = [[NSThread currentThread] description];
	[_lock lock];
	if (!_stacksDic[currentThread]) {
		_stacksDic[(id)currentThread] = [[ANEStack alloc] init];
	}
	[_lock unlock];
	return _stacksDic[currentThread];
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
