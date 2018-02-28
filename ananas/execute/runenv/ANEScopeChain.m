//
//  ANEScopeChain.m
//  ananasExample
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ANEScopeChain.h"
#import "ANEValue.h"
#import <objc/runtime.h>


@implementation ANEScopeChain
- (NSMutableDictionary<NSString *,ANEValue *> *)vars{
	if (_vars == nil) {
		_vars = [NSMutableDictionary dictionary];
	}
	return _vars;
}

+ (instancetype)scopeChainWithNext:(ANEScopeChain *)next{
	ANEScopeChain *scope = [ANEScopeChain new];
	scope.next = next;
	return scope;
}

- (ANEValue *)getValueWithIdentifier:(NSString *)identifier{
	for (ANEScopeChain *pos = self; pos; pos = pos.next) {
		if (pos.instance) {
			Ivar ivar = class_getInstanceVariable([pos.instance class], identifier.UTF8String);
			if (ivar) {
				const char *ivarEncoding = ivar_getTypeEncoding(ivar);
				void *ptr = (__bridge void *)(pos.instance) +  ivar_getOffset(ivar);
				ANEValue *value = [[ANEValue alloc] initWithCValuePointer:ptr typeEncoding:ivarEncoding];
				return value;
			}
		}else{
			__block ANEValue *value;
			[pos.vars enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ANEValue * _Nonnull obj, BOOL * _Nonnull stop) {
				if ([key isEqualToString:identifier]) {
					value = obj;
					*stop = YES;
				}
			}];
			if (value) {
				return value;
			}
			
		}
	}
	return nil;
}

@end

