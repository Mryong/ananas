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
	if (conValue.isTrue) {
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

static BOOL equal_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2){
#define number_equal(sel)\
	switch (value2.type.typeKind) {\
		case ANC_TYPE_BOOL:\
			return value1.sel == value2.boolValue;\
		case ANC_TYPE_NS_U_INTEGER:\
			return value1.sel == value2.uintValue;\
		case ANC_TYPE_NS_INTEGER:\
			return value1.sel == value2.intValue;\
		case ANC_TYPE_CG_FLOAT:\
			return value1.sel == value2.cgFloatValue;\
		case ANC_TYPE_DOUBLE:\
			return value1.sel == value2.doubleValue;\
		default:\
			NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.identifer, value2.type.identifer);\
			break;\
	}
	
#define object_equal(sel)\
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
			number_equal(boolValue);
		}
		case ANC_TYPE_NS_U_INTEGER:{
			number_equal(uintValue);
		}
		case ANC_TYPE_NS_INTEGER:{
			number_equal(intValue);
		}
		case ANC_TYPE_CG_FLOAT:{
			number_equal(cgFloatValue);
		}
		case ANC_TYPE_DOUBLE:{
			number_equal(doubleValue);
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
			object_equal(classValue);
		}
		case ANC_TYPE_NS_OBJECT:{
			object_equal(nsObjValue);
		}
		case ANC_TYPE_NS_BLOCK:{
			object_equal(nsBlockValue);
		}
		case ANC_TYPE_ANANAS_BLOCK:{
			object_equal(ananasBlockValue);
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
#undef number_equal
#undef object_equal
	return NO;
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
		default:
			break;
	}
	
}

ANEValue *ane_eval_expression(id _self,ANCInterpreter *inter, ANEScopeChain *scope,ANCExpression *expr){
	eval_expression(_self ,inter, scope, expr);
	return [inter.stack pop];
}

