//
//  eval.m
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "anc_ast.h"
#import "ANEEnvironment.h"
#import "ananasc.h"
#import <objc/message.h>
//ANC_BOOLEAN_EXPRESSION = 1,
//ANC_INT_EXPRESSION,
//ANC_U_INT_EXPRESSION,
//ANC_FLOAT_EXPRESSION,
//ANC_DOUBLE_EXPRESSION,
//ANC_STRING_EXPRESSION,
//ANC_SELECTOR_EXPRESSION,
//ANC_BLOCK_EXPRESSION,
//ANC_IDENTIFIER_EXPRESSION,
//ANC_TERNARY_EXPRESSION,
//ANC_ASSIGN_EXPRESSION,
//ANC_PLUS_EXPRESSION,
//ANC_MINUS_EXPRESSION,
//ANC_MUL_EXPRESSION,
//ANC_DIV_EXPRESSION,
//ANC_MOD_EXPRESSION,
//ANC_EQ_EXPRESSION,
//ANC_NE_EXPRESSION,
//ANC_GT_EXPRESSION,
//ANC_GE_EXPRESSION,
//ANC_LT_EXPRESSION,
//ANC_LE_EXPRESSION,
//ANC_LOGICAL_AND_EXPRESSION,
//ANC_LOGICAL_OR_EXPRESSION,
//ANC_LOGICAL_NOT_EXPRESSION,
//NSC_NEGATIVE_EXPRESSION,
//ANC_FUNCTION_CALL_EXPRESSION,
//ANC_MEMBER_EXPRESSION,
//ANC_NIL_EXPRESSION,
//ANC_SELF_EXPRESSION,
//ANC_SUPER_EXPRESSION,
//ANC_ARRAY_LITERAL_EXPRESSION,
//ANC_DIC_LITERAL_EXPRESSION,
//ANC_STRUCT_LITERAL_EXPRESSION,
//ANC_INDEX_EXPRESSION,
//ANC_INCREMENT_EXPRESSION,
//ANC_DECREMENT_EXPRESSION,
//ANC_AT_EXPRESSION

static void eval_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, __kindof ANCExpression *expr);

static void eval_bool_exprseeion(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	value.boolValue = expr.bool_value;
	[inter.stack push:value];
}

static void eval_ns_interger_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
	value.intValue = expr.integer_value;
	[inter.stack push:value];
}

static void eval_double_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_DOUBLE, @"long double", @"D");
	value.doubleValue = expr.double_value;
	[inter.stack push:value];
}

static void eval_string_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_STRING, @"char *", @"*");
	value.stringValue = expr.utf8_string_value;
	[inter.stack push:value];
}

static void eval_sel_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_STRING, @"SEL", @":");
	value.selValue = NSSelectorFromString(expr.selectorName);
	[inter.stack push:value];
}

static void eval_block_expression(ANCInterpreter *inter, ANEScopeChain *outScope, ANCBlockExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_ANANAS_BLOCK, @"", @"@?");
	ANEBlock *ananasBlockValue = [[ANEBlock alloc] init];
	ananasBlockValue.func = expr.func;
	ANEScopeChain *scope = [ANEScopeChain new];
	scope.next = outScope;
	ananasBlockValue.scope = scope;
	value.ananasBlockValue = ananasBlockValue;
	[inter.stack push:value];
}

static void eval_nil_expr(ANCInterpreter *inter){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_STRING, @"SEL", @":");
	value.nsObjValue = nil;
	[inter.stack push:value];
}

static void eval_self_expreesion(ANCInterpreter *inter, id _self){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"id", @"@");
	value.nsObjValue = _self;
	[inter.stack push:value];
}


static void eval_super_expreesion(ANCInterpreter *inter, id _self){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"id", @"@");
	value.nsObjValue = _self;
	value.isSuper = YES;
	[inter.stack push:value];
}

static void eval_identifer_expression(ANCInterpreter *inter, ANEScopeChain *scope ,ANCIdentifierExpression *expr){
	NSString *identifier = expr.identifier;
	for (ANEScopeChain *pos = scope; pos; pos = pos.next) {
		if (pos.instance) {
			Ivar ivar = class_getInstanceVariable([pos.instance class], identifier.UTF8String);
			if (ivar) {
				ANEValue *value = [[ANEValue alloc] init];
				const char *ivarEncoding = ivar_getTypeEncoding(ivar);
				switch (*ivarEncoding) {
					case '*':{
						char **ivarValuePointer = (char **)((__bridge void *)(pos.instance) + ivar_getOffset(ivar));
						value.type = anc_create_type_specifier(ANC_TYPE_STRING, @"char *", @"*");
						value.stringValue = *ivarValuePointer;
						break;
					}
					case '@':{
						if (strlen(ivarEncoding) == 2) {
							value.type = anc_create_type_specifier(ANC_TYPE_NS_BLOCK, @"", @"@?");
						}else{
							NSScanner *scanner = [NSScanner scannerWithString:@(ivarEncoding)];
							if ([scanner scanString:@"@\"" intoString:NULL]) {
								NSString *clsName;
								[scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName];
								value.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, clsName, @"@");
							}else{
								value.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"", @"@");
							}
						}
						break;
					}
					case 'B':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"", @"B");
						value.boolValue = [num boolValue];
						break;
					}
					case 'i':
					case 's':
					case 'l':
					case 'q':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"", @"q");
						value.intValue = [num integerValue];
						break;
					}
					case 'I':
					case 'S':
					case 'L':
					case 'Q':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"", @"Q");
						value.uintValue = [num unsignedIntegerValue];
						break;
					}
					case 'f':
					case 'd':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"", @"d");
						value.cgFloatValue = [num doubleValue];
						break;
					}
					case 'D':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"", @"D");
						value.doubleValue = [num doubleValue];
						break;
					}
					case '{':{
						NSValue *value = [pos.instance valueForKey:identifier];
						//TODO
						break;
					}
					default:
						NSCAssert(0, @"not support type %s", ivarEncoding);
						break;
				}
				[inter.stack push:value];
				
				break;
			}
		}else{
			for (ANEVariable *var in scope.vars) {
				if ([var.name isEqualToString:identifier]) {
					[inter.stack push:var.value];
					break;
				}
			}
		}
	}
	NSCAssert(0, @"not found var %@", identifier);
}


static void eval_ternary_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCTernaryExpression *expr){
	eval_expression(_self, inter, scope, expr.condition);
	ANEValue *conValue = [inter.stack pop];
	if (conValue.isSubtantial) {
		if (expr.trueExpr) {
			eval_expression(_self, inter, scope, expr.trueExpr);
		}else{
			[inter.stack push:conValue];
		}
	}else{
		eval_expression(_self, inter, scope, expr.falseExpr);
	}
	
}
static void eval_assign_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCAssignExpression *expr){
	//TODO
}


#define arithmeticalOperation(operation,operationName) \
if (leftValue.type.typeKind == ANC_TYPE_DOUBLE || rightValue.type.typeKind == ANC_TYPE_DOUBLE) {\
resultValue.type = anc_create_type_specifier(ANC_TYPE_DOUBLE, @"long double", @"D");\
if (leftValue.type.typeKind == ANC_TYPE_DOUBLE) {\
switch (rightValue.type.typeKind) {\
case ANC_TYPE_DOUBLE:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.doubleValue;\
break;\
case ANC_TYPE_CG_FLOAT:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.cgFloatValue;\
break;\
case ANC_TYPE_NS_INTEGER:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.intValue;\
break;\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.uintValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);\
break;\
}\
}else{\
switch (leftValue.type.typeKind) {\
case ANC_TYPE_CG_FLOAT:\
resultValue.doubleValue = leftValue.cgFloatValue operation rightValue.doubleValue;\
break;\
case ANC_TYPE_NS_INTEGER:\
resultValue.doubleValue = leftValue.intValue operation rightValue.doubleValue;\
break;\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.doubleValue = leftValue.uintValue operation rightValue.doubleValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.left.lineNumber ,leftValue.type.identifer);\
break;\
}\
}\
}else if (leftValue.type.typeKind == ANC_TYPE_CG_FLOAT || rightValue.type.typeKind == ANC_TYPE_CG_FLOAT){\
resultValue.type = anc_create_type_specifier(ANC_TYPE_CG_FLOAT, @"CGFloat", @"D");\
if (leftValue.type.typeKind == ANC_TYPE_CG_FLOAT) {\
switch (rightValue.type.typeKind) {\
case ANC_TYPE_CG_FLOAT:\
resultValue.cgFloatValue = leftValue.cgFloatValue operation rightValue.cgFloatValue;\
break;\
case ANC_TYPE_NS_INTEGER:\
resultValue.cgFloatValue = leftValue.cgFloatValue operation rightValue.intValue;\
break;\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.cgFloatValue = leftValue.cgFloatValue operation rightValue.uintValue;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);\
break;\
}\
}else{\
switch (leftValue.type.typeKind) {\
case ANC_TYPE_NS_INTEGER:\
resultValue.cgFloatValue = leftValue.intValue operation rightValue.cgFloatValue;\
break;\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.cgFloatValue = leftValue.uintValue operation rightValue.cgFloatValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.left.lineNumber ,leftValue.type.identifer);\
break;\
}\
}\
}else if (leftValue.type.typeKind == ANC_TYPE_NS_INTEGER || rightValue.type.typeKind == ANC_TYPE_NS_INTEGER){\
if (leftValue.type.typeKind == ANC_TYPE_NS_INTEGER) {\
switch (rightValue.type.typeKind) {\
case ANC_TYPE_NS_INTEGER:\
resultValue.intValue = leftValue.intValue operation rightValue.intValue;\
break;\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.intValue = leftValue.intValue operation rightValue.uintValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);\
break;\
}\
}else{\
switch (leftValue.type.typeKind) {\
case ANC_TYPE_NS_U_INTEGER:\
resultValue.intValue = leftValue.uintValue operation rightValue.intValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.left.lineNumber ,leftValue.type.identifer);\
break;\
}\
}\
}else if (leftValue.type.typeKind == ANC_U_INT_EXPRESSION && rightValue.type.typeKind == ANC_U_INT_EXPRESSION){\
resultValue.uintValue = leftValue.uintValue operation rightValue.uintValue;\
}else{\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);\
}\


static void eval_add_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];\
	arithmeticalOperation(+,add);
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}


static void eval_sub_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];\
	arithmeticalOperation(-,sub);
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}


static void eval_mul_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	arithmeticalOperation(*,mul);
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}


static void eval_div_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	switch (rightValue.type.typeKind) {
		case ANC_TYPE_DOUBLE:
			if (rightValue.doubleValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
			break;
		case ANC_TYPE_CG_FLOAT:
			if (rightValue.cgFloatValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
		case ANC_TYPE_NS_INTEGER:
			if (rightValue.intValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
		case ANC_TYPE_UNKNOWN:
			if (rightValue.uintValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
			break;
			
		default:
			NSCAssert(0, @"line:%zd, div operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);
			break;
	}
	ANEValue *resultValue = [ANEValue new];\
	arithmeticalOperation(/,div);
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}



static void eval_mod_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	ANEValue *leftValue = [inter.stack peekStack:0];
	if (leftValue.type.typeKind != ANC_TYPE_NS_INTEGER && leftValue.type.typeKind != ANC_TYPE_NS_U_INTEGER) {
		NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.left.lineNumber ,leftValue.type.identifer);
	}
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *rightValue = [inter.stack peekStack:0];
	if (rightValue.type.typeKind != ANC_TYPE_NS_INTEGER && rightValue.type.typeKind != ANC_TYPE_NS_U_INTEGER) {
		NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);
	}
	switch (rightValue.type.typeKind) {
		case ANC_TYPE_NS_INTEGER:
			if (rightValue.intValue == 0) {
				NSCAssert(0, @"line:%zd,mod cannot be zero!",expr.right.lineNumber);
			}
		case ANC_TYPE_UNKNOWN:
			if (rightValue.uintValue == 0) {
				NSCAssert(0, @"line:%zd,mod cannot be zero!",expr.right.lineNumber);
			}
			break;
			
		default:
			NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.right.lineNumber ,rightValue.type.identifer);
			break;
	}
	ANEValue *resultValue = [ANEValue new];
	if (leftValue.type.typeKind == ANC_TYPE_NS_INTEGER || leftValue.type.typeKind == ANC_TYPE_NS_INTEGER) {
		resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
		if (leftValue.type.typeKind == ANC_TYPE_NS_INTEGER) {
			if (rightValue.type.typeKind == ANC_TYPE_NS_INTEGER) {
				resultValue.intValue = leftValue.intValue % rightValue.intValue;
			}else{
				resultValue.intValue = leftValue.intValue % rightValue.uintValue;
			}
		}else{
			resultValue.intValue = leftValue.uintValue % rightValue.intValue;
		}
	}else{
		resultValue.type = anc_create_type_specifier(ANC_TYPE_UNKNOWN, @"NSUInteger", @"Q");
		resultValue.uintValue = leftValue.uintValue % rightValue.uintValue;
	}
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}
#define number_value_compare(sel,oper)\
switch (value2.type.typeKind) {\
case ANC_TYPE_BOOL:\
return value1.sel oper value2.boolValue;\
case ANC_TYPE_NS_U_INTEGER:\
return value1.sel oper value2.uintValue;\
case ANC_TYPE_NS_INTEGER:\
return value1.sel oper value2.intValue;\
case ANC_TYPE_CG_FLOAT:\
return value1.sel oper value2.cgFloatValue;\
case ANC_TYPE_DOUBLE:\
return value1.sel oper value2.doubleValue;\
default:\
NSCAssert(0, @"line:%zd == 、 != 、 < 、 <= 、 > 、 >= can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);\
break;\
}
static BOOL equal_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2){

	
#define object_value_equal(sel)\
switch (value2.type.typeKind) {\
case ANC_TYPE_CLASS:\
	return value1.sel == value2.classValue;\
case ANC_TYPE_NS_OBJECT:\
	return value1.sel == value2.nsObjValue;\
case ANC_TYPE_NS_BLOCK:\
	return value1.sel == value2.nsBlockValue;\
case ANC_TYPE_ANANAS_BLOCK:\
	return value1.sel == value2.ananasBlockValue;\
case ANC_TYPE_UNKNOWN:\
	return value1.sel == value2.unknownKindValue;\
default:\
	NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);\
	break;\
}\
	
	switch (value1.type.typeKind) {
		case ANC_TYPE_BOOL:{
			number_value_compare(boolValue, ==);
		}
		case ANC_TYPE_NS_U_INTEGER:{
			number_value_compare(uintValue, ==);
		}
		case ANC_TYPE_NS_INTEGER:{
			number_value_compare(intValue, ==);
		}
		case ANC_TYPE_CG_FLOAT:{
			number_value_compare(cgFloatValue, ==);
		}
		case ANC_TYPE_DOUBLE:{
			number_value_compare(doubleValue, ==);
		}
		case ANC_TYPE_STRING:{
			switch (value2.type.typeKind) {
				case ANC_TYPE_STRING:
					 return value1.stringValue == value2.stringValue;
					break;
				case ANC_TYPE_UNKNOWN:
					return value1.stringValue == value2.unknownKindValue;
					break;
				default:
					NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);
					break;
			}
		}
		case ANC_TYPE_SEL:{
			if (value2.type.typeKind == ANC_TYPE_SEL) {
				return value1.selValue == value2.selValue;
			} else {
				NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);
			}
		}
		case ANC_TYPE_CLASS:{
			object_value_equal(classValue);
		}
		case ANC_TYPE_NS_OBJECT:{
			object_value_equal(nsObjValue);
		}
		case ANC_TYPE_NS_BLOCK:{
			object_value_equal(nsBlockValue);
		}
		case ANC_TYPE_ANANAS_BLOCK:{
			object_value_equal(ananasBlockValue);
		}
		case ANC_TYPE_UNKNOWN:{
			switch (value2.type.typeKind) {
				case ANC_TYPE_CLASS:
					return value2.classValue == value1.unknownKindValue;
				case ANC_TYPE_NS_OBJECT:
					return value2.nsObjValue == value1.unknownKindValue;
				case ANC_TYPE_NS_BLOCK:
					return value2.nsBlockValue == value1.unknownKindValue;
				case ANC_TYPE_ANANAS_BLOCK:
					return value2.ananasBlockValue == value1.unknownKindValue;
				case ANC_TYPE_UNKNOWN:
					return value2.unknownKindValue == value1.unknownKindValue;
				default:
					NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);
					break;
			}
		}
		case ANC_TYPE_STRUCT:{
			if (value2.type.typeKind == ANC_TYPE_STRUCT) {
				
			}else{
				NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);
				break;
			}
		}
			
		default:NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);
			break;
	}
#undef object_value_equal
	return NO;
}

static void eval_eq_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL equal =  equal_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = equal;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_ne_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL equal =  equal_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = !equal;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}



#define compare_number_func(prefix, oper)\
static BOOL prefix##_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2){\
switch (value1.type.typeKind) {\
	case ANC_TYPE_BOOL:\
		number_value_compare(boolValue, oper);\
	case ANC_TYPE_NS_U_INTEGER:\
		number_value_compare(uintValue, oper);\
	case ANC_TYPE_NS_INTEGER:\
		number_value_compare(intValue, oper);\
	case ANC_TYPE_CG_FLOAT:\
		number_value_compare(cgFloatValue, oper);\
	case ANC_TYPE_DOUBLE:\
		number_value_compare(doubleValue, oper);\
	default:\
		NSCAssert(0, @"line:%zd == 、 != 、 < 、 <= 、 > 、 >= can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);\
		break;\
}\
return NO;\
}

compare_number_func(lt, <)
compare_number_func(le, <=)
compare_number_func(ge, >)
compare_number_func(gt, >=)

static void eval_lt_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL lt = lt_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = lt;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}


static void eval_le_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL le = le_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = le;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_ge_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL ge = ge_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = ge;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}


static void eval_gt_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	BOOL gt = gt_value(expr.left.lineNumber, leftValue, rightValue);
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = gt;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_logic_and_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	ANEValue *leftValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	if (!leftValue.isSubtantial) {
		resultValue.boolValue = NO;
		[inter.stack pop];
	}else{
		eval_expression(_self, inter, scope, expr.right);
		ANEValue *rightValue = [inter.stack peekStack:0];
		if (!rightValue.isSubtantial) {
			resultValue.boolValue = NO;
		}else{
			resultValue.boolValue = YES;
		}
		[inter.stack pop];
	}
	[inter.stack push:resultValue];
}

static void eval_logic_or_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	ANEValue *leftValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	if (leftValue.isSubtantial) {
		resultValue.boolValue = YES;
		[inter.stack pop];
	}else{
		eval_expression(_self, inter, scope, expr.right);
		ANEValue *rightValue = [inter.stack peekStack:0];
		if (rightValue.isSubtantial) {
			resultValue.boolValue = YES;
		}else{
			resultValue.boolValue = NO;
		}
		[inter.stack pop];
	}
	[inter.stack push:resultValue];
}

static void eval_logic_not_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
	resultValue.boolValue = !value.isSubtantial;
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_increment_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	switch (value.type.typeKind) {
		case ANC_TYPE_NS_INTEGER:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
//			resultValue.intValue = value.intValue +
			break;
			
		default:
			break;
	}
}

static void eval_negative_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	switch (value.type.typeKind) {
		case ANC_TYPE_NS_INTEGER:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
			resultValue.intValue = -resultValue.intValue;
			break;
		case ANC_TYPE_NS_U_INTEGER:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
			resultValue.intValue = - resultValue.uintValue;
			break;
		case ANC_TYPE_BOOL:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
			resultValue.intValue = - resultValue.boolValue;
			break;
		case ANC_TYPE_CG_FLOAT:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"CGFloat", @"d");
			resultValue.cgFloatValue = - resultValue.cgFloatValue;
			break;
		case ANC_TYPE_DOUBLE:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"long double", @"D");
			resultValue.doubleValue = - resultValue.doubleValue;
			break;
			
		default:
			NSCAssert(0, @"line:%zd operator ‘-’ can not use type: %@",expr.expr.lineNumber, value.type.identifer);
			break;
	}
}

//todo 支持block 数组
static void eval_index_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCIndexExpression *expr){
	eval_expression(_self, inter, scope, expr.indexExpression);
	ANEValue *indexValue = [inter.stack peekStack:0];
	ANCTypeSpecifierKind kind = indexValue.type.typeKind;
	
	eval_expression(_self, inter, scope, expr.arrayExpression);
	ANEValue *arrValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"id", @"@");
	switch (kind) {
		case ANC_TYPE_BOOL:
			resultValue.nsObjValue = arrValue.nsObjValue[indexValue.boolValue];
			break;
		case ANC_TYPE_NS_INTEGER:
			resultValue.nsObjValue = arrValue.nsObjValue[indexValue.intValue];
			break;
		case ANC_TYPE_NS_U_INTEGER:
			resultValue.nsObjValue = arrValue.nsObjValue[indexValue.uintValue];
			break;
		case ANC_TYPE_CLASS:
			resultValue.nsObjValue = resultValue.nsObjValue[indexValue.classValue];
			break;
		case ANC_TYPE_NS_BLOCK:
			resultValue.nsObjValue = resultValue.nsObjValue[indexValue.nsBlockValue];
			break;
		case ANC_TYPE_NS_OBJECT:
			resultValue.nsObjValue = resultValue.nsBlockValue[indexValue.nsObjValue];
		default:
			NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.indexExpression.lineNumber, indexValue.type.identifer);
			break;
	}
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
	
	
}

static void eval_at_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"id", @"@");
	switch (value.type.typeKind) {
		case ANC_TYPE_BOOL:
			resultValue.nsObjValue = @(value.boolValue);
			break;
		case ANC_TYPE_NS_U_INTEGER:
			resultValue.nsObjValue = @(value.uintValue);
			break;
		case ANC_TYPE_NS_INTEGER:
			resultValue.nsObjValue = @(value.intValue);
			break;
		case ANC_TYPE_CG_FLOAT:
			resultValue.nsObjValue = @(value.cgFloatValue);
			return;
		case ANC_TYPE_DOUBLE:
			resultValue.nsObjValue = @((double)value.doubleValue);
			break;
		case ANC_TYPE_STRING:
			resultValue.nsObjValue = @(value.stringValue);
			break;
			
		default:
			NSCAssert(0, @"line:%zd operator ‘@’ can not use type: %@",expr.expr.lineNumber, value.type.identifer);
			break;
	}
}


static void eval_dic_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCDictionaryExpression *expr){
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	for (ANCDicEntry *entry in expr.entriesExpr) {
		eval_expression(_self, inter, scope, entry.keyExpr);
		ANEValue *keyValue = [inter.stack peekStack:0];
		switch (keyValue.type.typeKind) {
			case ANC_TYPE_BOOL:
			case ANC_TYPE_NS_U_INTEGER:
			case ANC_TYPE_NS_INTEGER:
			case ANC_TYPE_CG_FLOAT:
			case ANC_TYPE_DOUBLE:
			case ANC_TYPE_SEL:
			case ANC_TYPE_VOID:
		    case ANC_TYPE_STRUCT:
			case ANC_TYPE_STRING:
			case ANC_TYPE_UNKNOWN:
				NSCAssert(0, @"line:%zd key can not bee type:%@",entry.keyExpr.lineNumber, keyValue.type.identifer);
				break;
			default:
				break;
		}
		
		
		eval_expression(_self, inter, scope, entry.valueExpr);
		ANEValue *valueValue = [inter.stack peekStack:0];
		switch (valueValue.type.typeKind) {
			case ANC_TYPE_BOOL:
			case ANC_TYPE_NS_U_INTEGER:
			case ANC_TYPE_NS_INTEGER:
			case ANC_TYPE_CG_FLOAT:
			case ANC_TYPE_DOUBLE:
			case ANC_TYPE_SEL:
			case ANC_TYPE_VOID:
			case ANC_TYPE_STRUCT:
			case ANC_TYPE_STRING:
			case ANC_TYPE_UNKNOWN:
				NSCAssert(0, @"line:%zd value can not bee type:%@",entry.keyExpr.lineNumber, keyValue.type.identifer);
				break;
			default:
				break;
		}
		
#define SET_DIC_KEY_VALUE(sel)\
		switch (valueValue.type.typeKind) {\
			case ANC_TYPE_NS_OBJECT:\
				dic[(id<NSCopying>)keyValue.sel] = valueValue.nsObjValue;\
				break;\
			case ANC_TYPE_CLASS:\
				dic[(id<NSCopying>)keyValue.sel] = valueValue.classValue;\
				break;\
			case ANC_TYPE_NS_BLOCK:\
				dic[(id<NSCopying>)keyValue.sel] = valueValue.nsBlockValue;\
				break;\
			case ANC_TYPE_ANANAS_BLOCK:\
				dic[(id<NSCopying>)keyValue.sel] = valueValue.ananasBlockValue;\
			default:\
				break;\
		}
		
		switch (keyValue.type.typeKind) {
			case ANC_TYPE_NS_OBJECT:
				SET_DIC_KEY_VALUE(nsObjValue)
				break;
			case ANC_TYPE_CLASS:
				SET_DIC_KEY_VALUE(classValue)
				break;
			case ANC_TYPE_NS_BLOCK:
				SET_DIC_KEY_VALUE(nsBlockValue)
				break;
			case ANC_TYPE_ANANAS_BLOCK:
				SET_DIC_KEY_VALUE(ananasBlockValue)
				break;
				
			default:
				break;
		}
		
		[inter.stack pop];
		[inter.stack pop];
	}
#undef SET_DIC_KEY_VALUE
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"NSDictionary", @"@");
	resultValue.nsObjValue = dic.copy;
	[inter.stack push:resultValue];
	
}


static void eval_array_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCArrayExpression *expr){
	NSMutableArray *array = [NSMutableArray array];
	for (ANCExpression *elementExpr in array) {
		eval_expression(_self, inter, scope, elementExpr);
		ANEValue *elementValue = [inter.stack peekStack:0];
		switch (elementExpr.typeSpecifier.typeKind) {
			case ANC_TYPE_CLASS:
				[array addObject:elementValue.classValue];
				break;
			case ANC_TYPE_NS_OBJECT:
				[array addObject:elementValue.nsObjValue];
				break;
			case ANC_TYPE_NS_BLOCK:
				[array addObject:elementValue.nsBlockValue];
				break;
			case ANC_TYPE_ANANAS_BLOCK:
				[array addObject:elementValue.ananasBlockValue];
				break;
			default:
				NSCAssert(0, @"line:%zd array element type  can not bee type:%@",elementExpr.lineNumber, elementValue.type.identifer);
				break;
		}
		[inter.stack pop];
	}
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_OBJECT, @"NSArray", @"@");
	resultValue.nsObjValue = array.copy;
	[inter.stack push:resultValue];
}

static void eval_member_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCMemberExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *obj = [inter.stack peekStack:0];
	if (obj.type.typeKind != ANC_TYPE_NS_OBJECT) {
		NSCAssert(0, @"line:%zd, %@ is not object",expr.expr.lineNumber, obj.type.identifer);
	}
	
	ANEValue *returnValue = [ANEValue alloc];
	SEL sel = NSSelectorFromString(expr.memberName);
	if ([obj.nsObjValue respondsToSelector:sel]) {
		NSMethodSignature *sig =[_self methodSignatureForSelector:NSSelectorFromString(expr.memberName)];
		void *returnData = malloc([sig methodReturnLength]);
		char *returnTypeEncoding = (char *)[sig methodReturnType];
		size_t len = strlen(returnTypeEncoding);
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation setTarget:_self];
		[invocation setSelector:sel];
		[invocation invoke];
		[invocation getReturnValue:returnData];
		BOOL prefix = YES;
		while (prefix) {
			switch (*returnTypeEncoding) {
				case 'r':
				case 'n':
				case 'N':
				case 'o':
				case 'O':
				case 'R':
				case 'V':
					returnTypeEncoding++;
					break;
				default:
					prefix = NO;
					break;
			}
		}
		switch (*returnTypeEncoding) {
			case 'v': {
				NSCAssert(0, @"");
				break;
			}
			case 'B':{
				returnValue.type = anc_create_type_specifier(ANC_TYPE_BOOL, @"BOOL", @"B");
				returnValue.boolValue = *(BOOL *)returnData;
				break;
			}
			case 'c': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
				returnValue.intValue = *(int8_t *)returnData;
				break;
			}
			case 'C': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"NSUInteger", @"Q");
				returnValue.uintValue = *(uint8_t *)returnData;
				break;
			}
			case 's': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
				returnValue.intValue = *(int16_t *)returnData;
				break;
			}
			case 'S': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"NSUInteger", @"Q");
				returnValue.uintValue = *(uint16_t *)returnData;
				break;
			}
			case 'i': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
				returnValue.intValue = *(int32_t *)returnData;
				break;
			}
			case 'I': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"NSUInteger", @"Q");
				returnValue.uintValue = *(uint32_t *)returnData;
				break;
			}
			case 'l': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
				returnValue.intValue = *(int32_t *)returnData;
				break;
			}
			case 'L': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"NSUInteger", @"Q");
				returnValue.uintValue = *(uint32_t *)returnData;
				break;
			}
			case 'q':{
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER, @"NSInteger", @"q");
				returnValue.intValue = *(NSInteger *)returnData;
				break;
			}
			case 'Q': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER, @"NSUInteger", @"Q");
				returnValue.uintValue = *(NSUInteger *)returnData;
				break;
			}
			case 'f': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_CG_FLOAT, @"CGFloat", @"d");
				returnValue.cgFloatValue = *(CGFloat *)returnData;
				break;
			}
			case 'd': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_CG_FLOAT, @"CGFloat", @"d");
				returnValue.cgFloatValue = *(CGFloat *)returnData;
				break;
			}
			case 'D':{
				returnValue.type = anc_create_type_specifier(ANC_TYPE_DOUBLE, @"long double", @"D");
				returnValue.cgFloatValue = *(long double *)returnData;
				break;
			}
			case '#': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_CLASS, @"Class", @"#");
				returnValue.classValue = *(Class *)returnData;
				break;
			}
			case ':': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_SEL, @"SEL", @":");
				returnValue.selValue = *(SEL *)returnData;
				break;
			}
			case '*': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_STRING, @"char *", @"*");
				returnValue.stringValue = *(char * *)returnData;
				break;
			}
			case '^': {
				returnValue.type = anc_create_type_specifier(ANC_TYPE_UNKNOWN, @"void *", @"^");
				returnValue.stringValue = *(void * *)returnData;
				break;
			}
			case '[':
			case '(': {
				NSCAssert(0, @"line:%zd,not supprot c array and union type",expr.expr.lineNumber);
				break;
			}
			case '{':{
				//TODO
				break;
			}
			case '@': {
				if (len == 2 && *(returnTypeEncoding + 1) == '?'){
					returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_BLOCK, @"NSBlock", @"@?");
					returnValue.nsBlockValue = (__bridge_transfer id)(*(void **)returnData);
					break;
				}else{
					returnValue.type = anc_create_type_specifier(ANC_TYPE_NS_BLOCK, @"id", @"@");
					returnValue.nsObjValue = (__bridge_transfer id)(*(void **)returnData);
					break;
				}
				break;
			}
			default:{
				returnValue.type = anc_create_type_specifier(ANC_TYPE_UNKNOWN, @"void *", @"^");
				returnValue.stringValue = *(void * *)returnData;
				break;
			}
		}
		
		
		
	}else{
		//TODO
		
	}
	[inter.stack pop];
	[inter.stack push:returnValue];
}








static void eval_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, __kindof ANCExpression *expr){
	switch (expr.expressionKind) {
		case ANC_BOOLEAN_EXPRESSION:
			eval_bool_exprseeion(inter, expr);
			break;
		case ANC_INT_EXPRESSION:
			eval_ns_interger_expression(inter, expr);
			break;
		case ANC_DOUBLE_EXPRESSION:
			eval_double_expression(inter, expr);
			break;
		case ANC_STRING_EXPRESSION:
			eval_string_expression(inter, expr);
			break;
		case ANC_SELECTOR_EXPRESSION:
			eval_sel_expression(inter, expr);
			break;
		case ANC_BLOCK_EXPRESSION:
			eval_block_expression(inter, scope, expr);
			break;
		case ANC_NIL_EXPRESSION:
			eval_nil_expr(inter);
			break;
		case ANC_SELF_EXPRESSION:
			eval_self_expreesion(inter, _self);
			break;
		case ANC_SUPER_EXPRESSION:
			eval_super_expreesion(inter, _self);
			break;
		case ANC_IDENTIFIER_EXPRESSION:
			eval_identifer_expression(inter, scope, expr);
			break;
		case ANC_ASSIGN_EXPRESSION:
			eval_assign_expression(_self, inter, scope, expr);
			break;
		case ANC_PLUS_EXPRESSION:
			eval_add_expression(_self, inter, scope, expr);
			break;
		case ANC_MINUS_EXPRESSION:
			eval_sub_expression(_self, inter, scope, expr);
			break;
		case ANC_MUL_EXPRESSION:
			eval_mul_expression(_self, inter, scope, expr);
			break;
		case ANC_DIV_EXPRESSION:
			eval_div_expression(_self, inter, scope, expr);
			break;
		case ANC_MOD_EXPRESSION:
			eval_mod_expression(_self, inter, scope, expr);
			break;
		case ANC_EQ_EXPRESSION:
			eval_eq_expression(_self, inter, scope, expr);
			break;
		case ANC_NE_EXPRESSION:
			eval_ne_expression(_self, inter, scope, expr);
			break;
		case ANC_LT_EXPRESSION:
			eval_lt_expression(_self, inter, scope, expr);
			break;
		case ANC_LE_EXPRESSION:
			eval_le_expression(_self, inter, scope, expr);
			break;
		case ANC_GE_EXPRESSION:
			eval_ge_expression(_self, inter, scope, expr);
			break;
		case ANC_GT_EXPRESSION:
			eval_gt_expression(_self, inter, scope, expr);
			break;
		case ANC_LOGICAL_AND_EXPRESSION:
			eval_logic_and_expression(_self, inter, scope, expr);
			break;
		case ANC_LOGICAL_OR_EXPRESSION:
			eval_logic_or_expression(_self, inter, scope, expr);
			break;
		case ANC_LOGICAL_NOT_EXPRESSION:
			eval_logic_not_expression(_self, inter, scope, expr);
			break;
		case ANC_TERNARY_EXPRESSION:
			eval_ternary_expression(_self, inter, scope, expr);
			break;
			
		case ANC_INDEX_EXPRESSION:
			eval_index_expression(_self, inter, scope, expr);
			break;
		case ANC_AT_EXPRESSION:
			eval_at_expression(_self, inter, scope, expr);
			break;
		case NSC_NEGATIVE_EXPRESSION:
			eval_negative_expression(_self, inter, scope, expr);
			break;
		case ANC_MEMBER_EXPRESSION:
			eval_member_expression(_self, inter, scope, expr);
			break;
		case ANC_DIC_LITERAL_EXPRESSION:
			eval_dic_expression(_self, inter, scope, expr);
			break;
		case ANC_ARRAY_LITERAL_EXPRESSION:
			eval_array_expression(_self, inter, scope, expr);
			break;
		case ANC_INCREMENT_EXPRESSION:
			break;
		case ANC_DECREMENT_EXPRESSION:
			break;
		case ANC_STRUCT_LITERAL_EXPRESSION:
			break;
		case ANC_FUNCTION_CALL_EXPRESSION:
			break;
		default:
			break;
	}
	
}

ANEValue *ane_eval_expression(id _self,ANCInterpreter *inter, ANEScopeChain *scope,ANCExpression *expr){
	eval_expression(_self ,inter, scope, expr);
	return [inter.stack pop];
}

