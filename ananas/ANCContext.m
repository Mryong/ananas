//
//  ANCContext.m
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCContext.h"
#import "create.h"
#import "execute.h"

@interface ANCContext()
@property(nonatomic, strong) ANCInterpreter *interpreter;
@end

@implementation ANCContext


- (instancetype)init{
	if (self = [super init]) {
		_interpreter = [[ANCInterpreter alloc] init];
	}
	return self;
}

- (void)evalAnanasScriptWithURL:(NSURL *)url{
	anc_set_current_compile_util(self.interpreter);
	[self.interpreter compileSoruceWithURL:url];
	ane_interpret(self.interpreter);
	
	
}

- (void)evalAnanasScriptWithSourceString:(NSString *)sourceString{
	anc_set_current_compile_util(self.interpreter);
	[self.interpreter compileSoruceWithString:sourceString];
	ane_interpret(self.interpreter);
}

- (ANEValue *)objectForKeyedSubscript:(id)key{
	return _interpreter.topScope.vars[key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject<NSCopying> *)key{
	_interpreter.topScope.vars[key] = [ANEValue valueInstanceWithObject:object];
	
	
}


@end
