//
//  ANEEnvironment.m
//  ananasExample
//
//  Created by jerry.yong on 2018/1/2.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ANEEnvironment.h"
#import "util.h"
#import "ananasc.h"
#import "ANANASStructDeclareTable.h"
#import <objc/runtime.h>

@implementation ANEValue

- (instancetype)init{
	if (self = [super init]) {
	}
	return self;
}
- (BOOL)isSubtantial{
	switch (_type.typeKind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_U_INT:
			return _uintValue ? YES : NO;
		case ANC_TYPE_INT:
			return _integerValue ? YES : NO;
		case ANC_TYPE_DOUBLE:
			return _doubleValue ? YES : NO;
		case ANC_TYPE_C_STRING:
			return _cstringValue ? YES : NO;
		case ANC_TYPE_CLASS:
			return _classValue ? YES : NO;
		case ANC_TYPE_SEL:
			return _selValue ? YES : NO;
		case ANC_TYPE_OBJECT:
		case ANC_TYPE_STRUCT_LITERAL:
		case ANC_TYPE_BLOCK:
			return _objectValue ? YES : NO;
		case ANC_TYPE_STRUCT:
		case ANC_TYPE_POINTER:
			return _pointerValue ? YES : NO;
		case ANC_TYPE_VOID:
			return NO;
		default:
			break;
	}
	return NO;
	
}
- (BOOL)isMember{
	ANATypeSpecifierKind kind = _type.typeKind;
	switch (kind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_INT:
		case ANC_TYPE_U_INT:
		case ANC_TYPE_DOUBLE:
			return YES;
		default:
			return NO;
	}
}

- (BOOL)isObject{
	switch (_type.typeKind) {
		case ANC_TYPE_OBJECT:
		case ANC_TYPE_CLASS:
		case ANC_TYPE_BLOCK:
			return YES;
		default:
			return NO;
	}
}


- (BOOL)isBaseValue{
	return ![self isObject];
}

- (void)assignFrom:(ANEValue *)src{
	
	_type = src.type;
	_uintValue = src.uintValue;
	_integerValue = src.integerValue;
	_doubleValue = src.doubleValue;
	_classValue = src.classValue;
	_selValue = src.selValue;
	_objectValue = src.objectValue;
	_pointerValue = src.pointerValue;
	if (src.cstringValue) {
		char *cstringValue = malloc(strlen(src.cstringValue));
		strcpy(cstringValue, src.cstringValue);
		_cstringValue = cstringValue;
	}
}




- (unsigned long long)c2uintValue{
	switch (_type.typeKind) {
		case ANC_TYPE_BOOL:
			return _uintValue;
		case ANC_TYPE_INT:
			return _integerValue;
		case ANC_TYPE_U_INT:
			return _uintValue;
		case ANC_TYPE_DOUBLE:
			return _doubleValue;
		default:
			return 0;
	}
}

- (long long)c2integerValue{
	switch (_type.typeKind) {
		case ANC_TYPE_BOOL:
			return _uintValue;
		case ANC_TYPE_INT:
			return _integerValue;
		case ANC_TYPE_U_INT:
			return _uintValue;
		case ANC_TYPE_DOUBLE:
			return _doubleValue;
		default:
			return 0;
	}
}

- (double)c2doubleValue{
	switch (_type.typeKind) {
		case ANC_TYPE_BOOL:
			return _uintValue;
		case ANC_TYPE_INT:
			return _integerValue;
		case ANC_TYPE_U_INT:
			return _uintValue;
		case ANC_TYPE_DOUBLE:
			return _doubleValue;
		default:
			return 0.0;
	}
}

- (id)c2objectValue{
	switch (_type.typeKind) {
		case ANC_TYPE_CLASS:
			return _classValue;
		case ANC_TYPE_OBJECT:
		case ANC_TYPE_BLOCK:
			return _objectValue;
		case ANC_TYPE_POINTER:
			return (__bridge_transfer id)_pointerValue;
		default:
			return nil;
	}
	
}

- (void *)c2pointerValue{
	switch (_type.typeKind) {
		case ANC_TYPE_C_STRING:
			return (void *)_cstringValue;
		case ANC_TYPE_POINTER:
			return _pointerValue;
		case ANC_TYPE_CLASS:
			return (__bridge void*)_classValue;
		case ANC_TYPE_OBJECT:
		case ANC_TYPE_BLOCK:
			return (__bridge void*)_objectValue;
		default:
			return nil;
	}
}


- (void)assign2CValuePointer:(void *)cvaluePointer typeEncoding:(const char *)typeEncoding{
	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
#define ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE(_encode, _type, _sel)\
case _encode:{\
_type *ptr = (_type *)cvaluePointer;\
*ptr = (_type)[self _sel];\
break;\
}
	
	switch (*typeEncoding) {
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('c', char, c2integerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('i', int, c2integerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('s', short, c2integerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('l', long, c2integerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('q', long long, c2integerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('C', unsigned char, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('I', unsigned int, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('S', unsigned short, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('L', unsigned long, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('Q', unsigned long long, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('f', float, c2doubleValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('d', double, c2doubleValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('B', BOOL, c2uintValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('*', char *, c2pointerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE('^', void *, c2pointerValue)
		ANANAS_ASSIGN_2_C_VALUE_POINTER_CASE(':', SEL, selValue)
		case '@':{
			NSObject  * __autoreleasing  *ptr = (NSObject * __autoreleasing *)cvaluePointer;
			*ptr = [self c2objectValue];
			break;
		}
		case '#':{
			Class *ptr = (Class  *)cvaluePointer;
			*ptr = [self c2objectValue];
			break;
		}
		case '{':{
			if (_type.typeKind == ANC_TYPE_STRUCT) {
				size_t structSize = ananas_struct_size_with_encoding(typeEncoding);
				memcpy(cvaluePointer, self.pointerValue, structSize);
			}else if (_type.typeKind == ANC_TYPE_STRUCT_LITERAL){
				NSString *structName = ananas_struct_name_with_encoding(typeEncoding);
				ANANASStructDeclareTable *table = [ANANASStructDeclareTable shareInstance];
				ananas_struct_data_with_dic(cvaluePointer, _objectValue, [table getStructDeclareWithName:structName]);
			}
			break;
		}
		case 'v':{
			break;
		}
		default:
			NSCAssert(0, @"");
			break;
	}
}


- (instancetype)initWithCValuePointer:(void *)cValuePointer typeEncoding:(const char *)typeEncoding{
	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
	ANEValue *retValue = [ANEValue new];
	
#define ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE(_code,_kind, _type,_sel)\
case _code:{\
retValue.type = anc_create_type_specifier(_kind);\
retValue._sel = *(_type *)cValuePointer;\
break;\
}
	
	switch (*typeEncoding) {
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('c',ANC_TYPE_INT, char, integerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('i',ANC_TYPE_INT, int,integerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('s',ANC_TYPE_INT, short,integerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('l',ANC_TYPE_INT, long,integerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('q',ANC_TYPE_INT, long long,integerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('C',ANC_TYPE_U_INT, unsigned char, uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('I',ANC_TYPE_U_INT,  unsigned int, uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('S',ANC_TYPE_U_INT, unsigned short, uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('L',ANC_TYPE_U_INT,  unsigned long, uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('Q',ANC_TYPE_U_INT, unsigned long long,uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('B',ANC_TYPE_BOOL, BOOL, uintValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('f',ANC_TYPE_DOUBLE, float, doubleValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('d',ANC_TYPE_DOUBLE, double,doubleValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE(':',ANC_TYPE_SEL, SEL, selValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('^',ANC_TYPE_POINTER,void *, pointerValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('*',ANC_TYPE_C_STRING, char *,cstringValue)
			ANANASA_C_VALUE_CONVER_TO_ANANAS_VALUE_CASE('#',ANC_TYPE_CLASS, Class,classValue)
		case '@':{
			retValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
			retValue.objectValue = (__bridge_transfer id)(*(void **)cValuePointer);
			break;
		}
		case '{':{
			NSString *structName = ananas_struct_name_with_encoding(typeEncoding);
			retValue.type= anc_create_struct_type_specifier(structName);
			retValue.pointerValue = cValuePointer;
			break;
		}
			
		default:
			NSCAssert(0, @"not suppoert %s", typeEncoding);
			break;
	}
	
	return retValue;
}

+ (instancetype)voidValueInstance{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_VOID);
	return value;
}


+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	value.uintValue = boolValue;
	return value;
}
+ (instancetype)valueInstanceWithUint:(unsigned long long int)uintValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_U_INT);
	value.uintValue = uintValue;
	return value;
}
+ (instancetype)valueInstanceWithInt:(long long int)intValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_INT);
	value.integerValue = intValue;
	return value;
}
+ (instancetype)valueInstanceWithDouble:(double)doubleValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_DOUBLE);
	value.doubleValue = doubleValue;
	return value;
}
+ (instancetype)valueInstanceWithObject:(id)objValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	value.objectValue = objValue;
	return value;
}
+ (instancetype)valueInstanceWithBlock:(id)blockValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	value.objectValue = blockValue;
	return value;
}
+ (instancetype)valueInstanceWithClass:(Class)clazzValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_CLASS);
	value.classValue = clazzValue;
	return value;
}
+ (instancetype)valueInstanceWithSEL:(SEL)selValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_SEL);
	value.selValue = selValue;
	return value;
}
+ (instancetype)valueInstanceWithCstring:(const char *)cstringValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_C_STRING);
	value.cstringValue = cstringValue;
	return value;
}

+ (instancetype)valueInstanceWithPointer:(void *)pointerValue{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_POINTER);
	value.pointerValue = pointerValue;
	return value;
}

+ (instancetype)valueInstanceWithStruct:(void *)structValue typeEncoding:(const char *)typeEncoding{
	ANEValue *value = [[ANEValue alloc] init];
	value.type = anc_create_type_specifier(ANC_TYPE_SEL);
	value.type.structName = ananas_struct_name_with_encoding(typeEncoding);
	size_t size = ananas_struct_size_with_encoding(typeEncoding);
	value.pointerValue = malloc(size);
	memcpy(value.pointerValue, structValue, size);
	return value;
}

- (void)dealloc{
	if (_type.typeKind == ANC_TYPE_STRUCT) {
		free(_pointerValue);
	}
}
@end

@implementation ANEVariable

@end

@implementation ANEScopeChain
- (NSMutableArray<ANEVariable *> *)vars{
	if (_vars == nil) {
		_vars = [NSMutableArray array];
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
			for (ANEVariable *var in pos.vars) {
				if ([var.name isEqualToString:identifier]) {
					return var.value;
				}
			}
		}
	}
	return nil;
}

@end

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
