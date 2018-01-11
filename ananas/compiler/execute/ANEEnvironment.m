//
//  ANEEnvironment.m
//  ananasExample
//
//  Created by jerry.yong on 2018/1/2.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ANEEnvironment.h"

@implementation ANEValue

- (instancetype)init{
	if (self = [super init]) {
		_isSuper = NO;
	}
	return self;
}
//ANC_TYPE_VOID,
//ANC_TYPE_BOOL,
//ANC_TYPE_NS_U_INTEGER,
//ANC_TYPE_NS_INTEGER,
//ANC_TYPE_CG_FLOAT,
//ANC_TYPE_DOUBLE,
//ANC_TYPE_STRING,//char *
//ANC_TYPE_CLASS,
//ANC_TYPE_SEL,
//ANC_TYPE_OC,
//ANC_TYPE_STRUCT,
//ANC_TYPE_NS_BLOCK,
//ANC_TYPE_ANANAS_BLOCK,
//ANC_TYPE_UNKNOWN
- (BOOL)isSubtantial{
	switch (self.type.typeKind) {
		case ANC_TYPE_BOOL:
			return self.boolValue;
		case ANC_TYPE_NS_U_INTEGER:
			return self.uintValue ? YES : NO;
		case ANC_TYPE_NS_INTEGER:
			return self.intValue ? YES : NO;
		case ANC_TYPE_CG_FLOAT:
			return self.cgFloatValue ? YES : NO;
		case ANC_TYPE_DOUBLE:
			return self.doubleValue ? YES : NO;
		case ANC_TYPE_STRING:
			return self.stringValue ? YES : NO;
		case ANC_TYPE_CLASS:
			return self.classValue ? YES : NO;
		case ANC_TYPE_SEL:
			return self.selValue ? YES : NO;
		case ANC_TYPE_NS_OBJECT:
			return self.nsObjValue ? YES : NO;
		case ANC_TYPE_STRUCT:
			return YES;
		case ANC_TYPE_NS_BLOCK:
			return self.nsBlockValue ? YES : NO;
		case ANC_TYPE_ANANAS_BLOCK:
			return self.ananasBlockValue ? YES : NO;
		case ANC_TYPE_UNKNOWN:
			return self.unknownKindValue ? YES : NO;
		case ANC_TYPE_VOID:
			return NO;
		default:
			break;
	}
	
}
- (BOOL)isMember{
	ANCTypeSpecifierKind kind = self.type.typeKind;
	switch (kind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_NS_U_INTEGER:
		case ANC_TYPE_NS_INTEGER:
		case ANC_TYPE_CG_FLOAT:
		case ANC_TYPE_DOUBLE:
		default:
			return NO;
	}
}

- (BOOL)isObject{
	switch (self.type.typeKind) {
		case ANC_TYPE_NS_OBJECT:
		case ANC_TYPE_NS_BLOCK:
		case ANC_TYPE_CLASS:
		case ANC_TYPE_ANANAS_BLOCK:
		default:
			return NO;
	}
}


- (BOOL)isBaseValue{
	return ![self isObject];
}
@end

@implementation ANEVariable

@end

@implementation ANEScopeChain

@end

@implementation ANEStatementResult

@end


@implementation ANEStack{
	NSMutableArray<ANEValue *> *_arr;
}

- (instancetype)init{
	if (self = [super init]) {
		_arr = [NSMutableArray array];
	}
	return self;
}

- (void)push:(ANEValue *)value{
	[_arr addObject:value];
}

- (ANEValue *)pop{
	ANEValue *value = [_arr  lastObject];
	[_arr removeLastObject];
	return value;
}

- (ANEValue *)peekStack:(NSUInteger)index{
	ANEValue *value = _arr[_arr.count - 1 - index];
	return value;
}

- (void)shrinkStack:(NSUInteger)shrinkSize{
	[_arr removeObjectsInRange:NSMakeRange(_arr.count - shrinkSize, shrinkSize)];
}

@end
