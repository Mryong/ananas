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
#import "ffi.h"
#import "util.h"

static void eval_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, __kindof ANCExpression *expr);

static void eval_bool_exprseeion(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	value.uintValue = expr.boolValue;
	[inter.stack push:value];
}

static void eval_interger_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_INT);
	value.integerValue = expr.integerValue;
	[inter.stack push:value];
}

static void eval_double_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_DOUBLE);
	value.doubleValue = expr.doubleValue;
	[inter.stack push:value];
}

static void eval_string_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_C_STRING);
	value.cstringValue = expr.cstringValue;
	[inter.stack push:value];
}

static void eval_sel_expression(ANCInterpreter *inter, ANCExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_SEL);
	value.selValue = NSSelectorFromString(expr.selectorName);
	[inter.stack push:value];
}


//TODO
static void eval_block_expression(ANCInterpreter *inter, ANEScopeChain *outScope, ANCBlockExpression *expr){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_BLOCK);
	ANEBlock *ananasBlockValue = [[ANEBlock alloc] init];
	ananasBlockValue.func = expr.func;
	ANEScopeChain *scope = [ANEScopeChain new];
	scope.next = outScope;
	ananasBlockValue.scope = scope;
	value.objectValue = ananasBlockValue;
	[inter.stack push:value];
}

static void eval_nil_expr(ANCInterpreter *inter){
	ANEValue *value = [ANEValue new];
	value.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	value.objectValue = nil;
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
						value.type = anc_create_type_specifier(ANC_TYPE_C_STRING);
						value.cstringValue = *ivarValuePointer;
						break;
					}
					case '@':{
						if (strlen(ivarEncoding) == 2 && *(ivarEncoding +1) == '?') {
							value.type = anc_create_type_specifier(ANC_TYPE_BLOCK);
						}else{
							value.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
						}
						break;
					}
					case 'B':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_BOOL);
						value.uintValue = [num boolValue];
						break;
					}
					case 'i':
					case 's':
					case 'l':
					case 'q':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_INT);
						value.integerValue = [num integerValue];
						break;
					}
					case 'I':
					case 'S':
					case 'L':
					case 'Q':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_U_INT);
						value.uintValue = [num unsignedIntegerValue];
						break;
					}
					case 'f':
					case 'd':{
						NSNumber *num = [pos.instance valueForKey:identifier];
						value.type = anc_create_type_specifier(ANC_TYPE_DOUBLE);
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
				
				return;
			}
		}else{
			for (ANEVariable *var in scope.vars) {
				if ([var.name isEqualToString:identifier]) {
					[inter.stack push:var.value];
					return;
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
static void eval_function_call_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCFunctonCallExpression *expr);

static void eval_assign_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCAssignExpression *expr){
	ANCAssignKind assignKind = expr.assignKind;
	ANCExpression *leftExpr = expr.left;
	ANCExpression *rightExpr = expr.right;
	
	switch (leftExpr.expressionKind) {
		case ANC_MEMBER_EXPRESSION:{
			ANCMemberExpression *memberExpr = (ANCMemberExpression *)leftExpr;
			NSString *first = [[memberExpr.memberName substringToIndex:1] uppercaseString];
			NSString *other = memberExpr.memberName.length > 1 ? [memberExpr.memberName substringFromIndex:1] : nil;
			memberExpr.memberName = [NSString stringWithFormat:@"set%@%@:",first,other];
			ANCFunctonCallExpression *callExpr = [[ANCFunctonCallExpression alloc] init];
			callExpr.expressionKind = ANC_FUNCTION_CALL_EXPRESSION;
			callExpr.expr = memberExpr;
			
			if (assignKind == ANC_NORMAL_ASSIGN) {
				callExpr.args = @[rightExpr];
			}else{
				ANCBinaryExpression *binExpr = [[ANCBinaryExpression alloc] init];
				binExpr.left = leftExpr;
				binExpr.right = rightExpr;
				callExpr.args = @[binExpr];
				
				switch (assignKind) {
					case ANC_PLUS_ASSIGN:{
						binExpr.expressionKind = ANC_PLUS_EXPRESSION;
					}
					case ANC_MINUS_ASSIGN:{
						binExpr.expressionKind = ANC_MINUS_EXPRESSION;
					}
					case ANC_MUL_ASSIGN:{
						binExpr.expressionKind = ANC_MUL_ASSIGN;
					}
					case ANC_DIV_ASSIGN:{
						binExpr.expressionKind = ANC_DIV_ASSIGN;
					}
					case ANC_MOD_ASSIGN:{
						binExpr.expressionKind = ANC_MOD_ASSIGN;
					}
						
					default:
						break;
				}
				
			}
			
			
			eval_function_call_expression(_self, inter, scope, callExpr);
			break;
		}
			
		case ANC_IDENTIFIER_EXPRESSION:{
			ANCIdentifierExpression *identiferExpr = (ANCIdentifierExpression *)leftExpr;
			ANCExpression *optrExpr;
			if (assignKind == ANC_NORMAL_ASSIGN) {
				optrExpr = rightExpr;
			}else{
				ANCBinaryExpression *binExpr = [[ANCBinaryExpression alloc] init];
				binExpr.left = leftExpr;
				binExpr.right = rightExpr;
				optrExpr = binExpr;
				
				switch (assignKind) {
					case ANC_PLUS_ASSIGN:{
						binExpr.expressionKind = ANC_PLUS_EXPRESSION;
					}
					case ANC_MINUS_ASSIGN:{
						binExpr.expressionKind = ANC_MINUS_EXPRESSION;
					}
					case ANC_MUL_ASSIGN:{
						binExpr.expressionKind = ANC_MUL_ASSIGN;
					}
					case ANC_DIV_ASSIGN:{
						binExpr.expressionKind = ANC_DIV_ASSIGN;
					}
					case ANC_MOD_ASSIGN:{
						binExpr.expressionKind = ANC_MOD_ASSIGN;
					}
						
					default:
						break;
				}
				
			}
			
			eval_expression(_self, inter, scope, optrExpr);
			ANEValue *operValue = [inter.stack pop];
			
			for (ANEScopeChain *pos = scope; pos; pos = pos.next) {
				if (pos.instance) {
					Ivar ivar	= class_getInstanceVariable([_self class], identiferExpr.identifier.UTF8String);
					if (ivar) {
						
					}
					
				}else{
					for (ANEVariable *var in pos.vars) {
						if ([var.name isEqualToString:identiferExpr.identifier]) {
							[var.value assignFrom:operValue];
							return;
						}
					}
				}
				
				
			}
			
			
			Ivar ivar = class_getInstanceVariable([_self class], identiferExpr.identifier.UTF8String);
			ptrdiff_t offset = ivar_getOffset(ivar);
			void *ivarPtr = (__bridge void *)_self + offset;
			
			break;
		}
		case ANC_INDEX_EXPRESSION:{
			break;
		}
			
		default:
			break;
	}
	
	
	//TODO
}


#define arithmeticalOperation(operation,operationName) \
if (leftValue.type.typeKind == ANC_TYPE_DOUBLE || rightValue.type.typeKind == ANC_TYPE_DOUBLE) {\
resultValue.type = anc_create_type_specifier(ANC_TYPE_DOUBLE);\
if (leftValue.type.typeKind == ANC_TYPE_DOUBLE) {\
switch (rightValue.type.typeKind) {\
case ANC_TYPE_DOUBLE:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.doubleValue;\
break;\
case ANC_TYPE_INT:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.integerValue;\
break;\
case ANC_TYPE_U_INT:\
resultValue.doubleValue = leftValue.doubleValue operation rightValue.uintValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);\
break;\
}\
}else{\
switch (leftValue.type.typeKind) {\
case ANC_TYPE_INT:\
resultValue.doubleValue = leftValue.integerValue operation rightValue.doubleValue;\
break;\
case ANC_TYPE_U_INT:\
resultValue.doubleValue = leftValue.uintValue operation rightValue.doubleValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.left.lineNumber ,leftValue.type.typeName);\
break;\
}\
}\
}else if (leftValue.type.typeKind == ANC_TYPE_INT || rightValue.type.typeKind == ANC_TYPE_INT){\
if (leftValue.type.typeKind == ANC_TYPE_INT) {\
switch (rightValue.type.typeKind) {\
case ANC_TYPE_INT:\
resultValue.integerValue = leftValue.integerValue operation rightValue.integerValue;\
break;\
case ANC_TYPE_U_INT:\
resultValue.integerValue = leftValue.integerValue operation rightValue.uintValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);\
break;\
}\
}else{\
switch (leftValue.type.typeKind) {\
case ANC_TYPE_U_INT:\
resultValue.integerValue = leftValue.uintValue operation rightValue.integerValue;\
break;\
default:\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.left.lineNumber ,leftValue.type.typeName);\
break;\
}\
}\
}else if (leftValue.type.typeKind == ANC_TYPE_U_INT && rightValue.type.typeKind == ANC_TYPE_U_INT){\
resultValue.uintValue = leftValue.uintValue operation rightValue.uintValue;\
}else{\
NSCAssert(0, @"line:%zd, " #operationName  " operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);\
}


static void eval_add_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	eval_expression(_self, inter, scope, expr.left);
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *leftValue = [inter.stack peekStack:1];
	ANEValue *rightValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
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
		case ANC_TYPE_INT:
			if (rightValue.integerValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
			break;
		case ANC_TYPE_U_INT:
			if (rightValue.uintValue == 0) {
				NSCAssert(0, @"line:%zd,divisor cannot be zero!",expr.right.lineNumber);
			}
			break;
			
		default:
			NSCAssert(0, @"line:%zd, div operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);
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
	if (leftValue.type.typeKind != ANC_TYPE_INT && leftValue.type.typeKind != ANC_TYPE_U_INT) {
		NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.left.lineNumber ,leftValue.type.typeName);
	}
	eval_expression(_self, inter, scope, expr.right);
	ANEValue *rightValue = [inter.stack peekStack:0];
	if (rightValue.type.typeKind != ANC_TYPE_INT && rightValue.type.typeKind != ANC_TYPE_U_INT) {
		NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);
	}
	switch (rightValue.type.typeKind) {
		case ANC_TYPE_INT:
			if (rightValue.integerValue == 0) {
				NSCAssert(0, @"line:%zd,mod cannot be zero!",expr.right.lineNumber);
			}
			break;
		case ANC_TYPE_U_INT:
			if (rightValue.uintValue == 0) {
				NSCAssert(0, @"line:%zd,mod cannot be zero!",expr.right.lineNumber);
			}
			break;
			
		default:
			NSCAssert(0, @"line:%zd, mod operation not support type: %@",expr.right.lineNumber ,rightValue.type.typeName);
			break;
	}
	ANEValue *resultValue = [ANEValue new];
	if (leftValue.type.typeKind == ANC_TYPE_INT || leftValue.type.typeKind == ANC_TYPE_INT) {
		resultValue.type = anc_create_type_specifier(ANC_TYPE_INT);
		if (leftValue.type.typeKind == ANC_TYPE_INT) {
			if (rightValue.type.typeKind == ANC_TYPE_INT) {
				resultValue.integerValue = leftValue.integerValue % rightValue.integerValue;
			}else{
				resultValue.integerValue = leftValue.integerValue % rightValue.uintValue;
			}
		}else{
			resultValue.integerValue = leftValue.uintValue % rightValue.integerValue;
		}
	}else{
		resultValue.type = anc_create_type_specifier(ANC_TYPE_U_INT);
		resultValue.uintValue = leftValue.uintValue % rightValue.uintValue;
	}
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}
#define number_value_compare(sel,oper)\
switch (value2.type.typeKind) {\
case ANC_TYPE_BOOL:\
return value1.sel oper value2.uintValue;\
case ANC_TYPE_U_INT:\
return value1.sel oper value2.uintValue;\
case ANC_TYPE_INT:\
return value1.sel oper value2.integerValue;\
case ANC_TYPE_DOUBLE:\
return value1.sel oper value2.doubleValue;\
default:\
NSCAssert(0, @"line:%zd == 、 != 、 < 、 <= 、 > 、 >= can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);\
break;\
}
static BOOL equal_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2){

	
#define object_value_equal(sel)\
switch (value2.type.typeKind) {\
case ANC_TYPE_CLASS:\
	return value1.sel == value2.classValue;\
case ANC_TYPE_OBJECT:\
case ANC_TYPE_BLOCK:\
	return value1.sel == value2.objectValue;\
case ANC_TYPE_POINTER:\
	return value1.sel == value2.pointerValue;\
default:\
	NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);\
	break;\
}\

	switch (value1.type.typeKind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_U_INT:{
			number_value_compare(uintValue, ==);
		}
		case ANC_TYPE_INT:{
			number_value_compare(integerValue, ==);
		}
		case ANC_TYPE_DOUBLE:{
			number_value_compare(doubleValue, ==);
		}
		case ANC_TYPE_C_STRING:{
			switch (value2.type.typeKind) {
				case ANC_TYPE_C_STRING:
					 return value1.cstringValue == value2.cstringValue;
					break;
				case ANC_TYPE_POINTER:
					return value1.cstringValue == value2.pointerValue;
					break;
				default:
					NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);
					break;
			}
		}
		case ANC_TYPE_SEL:{
			if (value2.type.typeKind == ANC_TYPE_SEL) {
				return value1.selValue == value2.selValue;
			} else {
				NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);
			}
		}
		case ANC_TYPE_CLASS:{
			object_value_equal(classValue);
		}
		case ANC_TYPE_OBJECT:
		case ANC_TYPE_BLOCK:{
			object_value_equal(objectValue);
		}
		case ANC_TYPE_POINTER:{
			switch (value2.type.typeKind) {
				case ANC_TYPE_CLASS:
					return value2.classValue == value1.pointerValue;
				case ANC_TYPE_OBJECT:
					return value2.objectValue == value1.pointerValue;
				case ANC_TYPE_BLOCK:
					return value2.objectValue == value1.pointerValue;
				case ANC_TYPE_POINTER:
					return value2.pointerValue == value1.pointerValue;
				default:
					NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);
					break;
			}
		}
		case ANC_TYPE_STRUCT:{
			if (value2.type.typeKind == ANC_TYPE_STRUCT) {
				//todo
			}else{
				NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);
				break;
			}
		}
			
		default:NSCAssert(0, @"line:%zd == and != can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = equal;
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = !equal;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}



#define compare_number_func(prefix, oper)\
static BOOL prefix##_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2){\
switch (value1.type.typeKind) {\
	case ANC_TYPE_BOOL:\
	case ANC_TYPE_U_INT:\
		number_value_compare(uintValue, oper);\
	case ANC_TYPE_INT:\
		number_value_compare(integerValue, oper);\
	case ANC_TYPE_DOUBLE:\
		number_value_compare(doubleValue, oper);\
	default:\
		NSCAssert(0, @"line:%zd == 、 != 、 < 、 <= 、 > 、 >= can not use between %@ and %@",lineNumber, value1.type.typeName, value2.type.typeName);\
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = lt;
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = le;
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = ge;
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = gt;
	[inter.stack pop];
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_logic_and_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	ANEValue *leftValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	if (!leftValue.isSubtantial) {
		resultValue.uintValue = NO;
		[inter.stack pop];
	}else{
		eval_expression(_self, inter, scope, expr.right);
		ANEValue *rightValue = [inter.stack peekStack:0];
		if (!rightValue.isSubtantial) {
			resultValue.uintValue = NO;
		}else{
			resultValue.uintValue = YES;
		}
		[inter.stack pop];
	}
	[inter.stack push:resultValue];
}

static void eval_logic_or_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCBinaryExpression *expr){
	eval_expression(_self, inter, scope, expr.left);
	ANEValue *leftValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	if (leftValue.isSubtantial) {
		resultValue.uintValue = YES;
		[inter.stack pop];
	}else{
		eval_expression(_self, inter, scope, expr.right);
		ANEValue *rightValue = [inter.stack peekStack:0];
		if (rightValue.isSubtantial) {
			resultValue.uintValue = YES;
		}else{
			resultValue.uintValue = NO;
		}
		[inter.stack pop];
	}
	[inter.stack push:resultValue];
}

static void eval_logic_not_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_BOOL);
	resultValue.uintValue = !value.isSubtantial;
	[inter.stack pop];
	[inter.stack push:resultValue];
}

static void eval_increment_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	switch (value.type.typeKind) {
		case ANC_TYPE_INT:
//			resultValue.type = anc_create_type_specifier(ANC_TYPE_NS_INTEGER);
//			resultValue.integerValue = value.integerValue +
			break;
			
		default:
			break;
	}
}

static void eval_negative_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCUnaryExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *value = [inter.stack pop];
	ANEValue *resultValue = [ANEValue new];
	switch (value.type.typeKind) {
		case ANC_TYPE_INT:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_INT);
			resultValue.integerValue = -value.integerValue;
			break;
		case ANC_TYPE_BOOL:
		case ANC_TYPE_U_INT:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_U_INT);
			resultValue.integerValue = - value.uintValue;
			break;
		case ANC_TYPE_DOUBLE:
			resultValue.type = anc_create_type_specifier(ANC_TYPE_DOUBLE);
			resultValue.doubleValue = - value.doubleValue;
			break;
			
		default:
			NSCAssert(0, @"line:%zd operator ‘-’ can not use type: %@",expr.expr.lineNumber, value.type.typeName);
			break;
	}
}

//todo 支持block 数组
static void eval_index_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCIndexExpression *expr){
	eval_expression(_self, inter, scope, expr.indexExpression);
	ANEValue *indexValue = [inter.stack peekStack:0];
	ANATypeSpecifierKind kind = indexValue.type.typeKind;
	
	eval_expression(_self, inter, scope, expr.arrayExpression);
	ANEValue *arrValue = [inter.stack peekStack:0];
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	switch (kind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_U_INT:
			resultValue.objectValue = arrValue.objectValue[indexValue.uintValue];
			break;
		case ANC_TYPE_INT:
			resultValue.objectValue = arrValue.objectValue[indexValue.integerValue];
			break;
		default:
			NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.indexExpression.lineNumber, indexValue.type.typeName);
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
	resultValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	switch (value.type.typeKind) {
		case ANC_TYPE_BOOL:
		case ANC_TYPE_U_INT:
			resultValue.objectValue = @(value.uintValue);
			break;
		case ANC_TYPE_INT:
			resultValue.objectValue = @(value.integerValue);
			break;
		case ANC_TYPE_DOUBLE:
			resultValue.objectValue = @(value.doubleValue);
			break;
		case ANC_TYPE_C_STRING:
			resultValue.objectValue = @(value.cstringValue);
			break;
			
		default:
			NSCAssert(0, @"line:%zd operator ‘@’ can not use type: %@",expr.expr.lineNumber, value.type.typeName);
			break;
	}
}


static void eval_struct_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCStructpression *expr){
	NSMutableDictionary *structDic = [NSMutableDictionary dictionary];
	NSUInteger count = expr.keys.count;
	for (NSUInteger i = 0; i < count; i++) {
		NSString *key = expr.keys[i];
		ANCExpression *itemExpr = expr.valueExpressions[i];
		eval_expression(_self, inter, scope, itemExpr);
		ANEValue *value = [inter.stack peekStack:0];
		if (value.isObject) {
			NSCAssert(0, @"line:%zd, struct can not support object type %@", itemExpr.lineNumber, value.type.typeName );
		}
		switch (value.type.typeKind) {
			case ANC_TYPE_BOOL:
			case ANC_TYPE_U_INT:
				structDic[key] = @(value.uintValue);
				break;
			case ANC_TYPE_INT:
				structDic[key] = @(value.integerValue);
				break;
			case ANC_TYPE_DOUBLE:
				structDic[key] = @(value.doubleValue);
				break;
			case ANC_TYPE_C_STRING:
				structDic[key] = [NSValue valueWithPointer:value.cstringValue];
				break;
			case ANC_TYPE_SEL:
				structDic[key] = [NSValue valueWithPointer:value.selValue];
				break;
			case ANC_TYPE_STRUCT:
				//todo
				break;
			case ANC_TYPE_STRUCT_LITERAL:
				structDic[key] = value.objectValue;
				break;
			case ANC_TYPE_POINTER:
				structDic[key] = [NSValue valueWithPointer:value.pointerValue];
				break;
				
			default:
				NSCAssert(0, @"");
				break;
		}
		
		[inter.stack pop];
		
	}
	
	ANEValue *result = [[ANEValue alloc] init];
	result.type = anc_create_type_specifier(ANC_TYPE_STRUCT_LITERAL);
	result.objectValue = [structDic copy];
	[inter.stack push:result];
}




static void eval_dic_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCDictionaryExpression *expr){
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	for (ANCDicEntry *entry in expr.entriesExpr) {
		eval_expression(_self, inter, scope, entry.keyExpr);
		ANEValue *keyValue = [inter.stack peekStack:0];
		if (!keyValue.isObject) {
			NSCAssert(0, @"line:%zd key can not bee type:%@",entry.keyExpr.lineNumber, keyValue.type.typeName);
		}
		
		
		
		eval_expression(_self, inter, scope, entry.valueExpr);
		ANEValue *valueValue = [inter.stack peekStack:0];
		if (!valueValue.isObject) {
			NSCAssert(0, @"line:%zd value can not bee type:%@",entry.keyExpr.lineNumber, valueValue.type.typeName);
		}

		dic[keyValue.c2objectValue] = valueValue.c2objectValue;
		
		[inter.stack pop];
		[inter.stack pop];
	}
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	resultValue.objectValue = dic.copy;
	[inter.stack push:resultValue];
	
}


static void eval_array_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCArrayExpression *expr){
	NSMutableArray *array = [NSMutableArray array];
	for (ANCExpression *elementExpr in array) {
		eval_expression(_self, inter, scope, elementExpr);
		ANEValue *elementValue = [inter.stack peekStack:0];
		if (elementValue.isObject) {
			[array addObject:elementValue.c2objectValue];
		}else{
			NSCAssert(0, @"line:%zd array element type  can not bee type:%@",elementExpr.lineNumber, elementValue.type.typeName);
		}
		
		[inter.stack pop];
	}
	ANEValue *resultValue = [ANEValue new];
	resultValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	resultValue.objectValue = array.copy;
	[inter.stack push:resultValue];
}






static ANEValue *get_struct_field_value(void *structData,ANCStructDeclare *declare,NSString *key){
	NSString *typeEncoding = [NSString stringWithUTF8String:declare.typeEncoding];
	NSString *types = [typeEncoding substringToIndex:typeEncoding.length-1];
	NSUInteger location = [types rangeOfString:@"="].location+1;
	types = [types substringFromIndex:location];
	const char *encoding = types.UTF8String;
	size_t postion = 0;
	NSUInteger index = [declare.keys indexOfObject:key];
	if (index == NSNotFound) {
		NSCAssert(0, @"key %@ not found of struct %@", key, declare.name);
	}
	ANEValue *retValue = [[ANEValue alloc] init];
	NSUInteger i = 0;
	for (size_t j = 0; j < declare.keys.count; j++) {
#define ANANAS_GET_STRUCT_FIELD_VALUE_CASE(_code,_type,_kind,_sel)\
case _code:{\
if (j == index) {\
_type value = *(_type *)(structData + postion);\
retValue.type = anc_create_type_specifier(_kind);\
retValue._sel = value;\
return retValue;\
}\
postion += sizeof(_type);\
break;\
}
		switch (encoding[i]) {
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('c',char,ANC_TYPE_INT,integerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('i',int,ANC_TYPE_INT,integerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('s',short,ANC_TYPE_INT,integerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('l',long,ANC_TYPE_INT,integerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('q',long long,ANC_TYPE_INT,integerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('C',unsigned char,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('I',unsigned int,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('S',unsigned short,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('L',unsigned long,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('Q',unsigned long long,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('f',float,ANC_TYPE_DOUBLE,doubleValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('d',double,ANC_TYPE_DOUBLE,doubleValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('B',BOOL,ANC_TYPE_U_INT,uintValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('^',void *,ANC_TYPE_POINTER,pointerValue);
				ANANAS_GET_STRUCT_FIELD_VALUE_CASE('*',char *,ANC_TYPE_C_STRING,cstringValue);
			
		
			case '{':{
				size_t stackSize = 1;
				size_t end = index + 1;
				for (char c = encoding[end]; c ; end++, c = encoding[end]) {
					if (c == '{') {
						stackSize++;
					}else if (c == '}') {
						stackSize--;
						if (stackSize == 0) {
							break;
						}
					}
				}
				
				NSString *subTypeEncoding = [types substringWithRange:NSMakeRange(index, end - index + 1)];
				if(j == index){
					void *value = structData + postion;
					ANEValue *retValue = [[ANEValue alloc] init];
					NSString *subStruct = ananas_struct_name_with_encoding(subTypeEncoding.UTF8String);
					//todo
					retValue.type = anc_create_struct_type_specifier(subStruct);
					retValue.pointerValue = value;
					return retValue;
				}
				
				size_t size = ananas_struct_size_with_encoding(subTypeEncoding.UTF8String);
				postion += size;
				i += end - index;
				break;
			}
			default:
				break;
		}
		i++;
	}
	NSCAssert(0, @"struct %@ typeEncoding error %@", declare.name, typeEncoding);
	return nil;
}

static void eval_member_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCMemberExpression *expr){
	eval_expression(_self, inter, scope, expr.expr);
	ANEValue *obj = [inter.stack peekStack:0];
	if (obj.type.typeKind == ANC_TYPE_STRUCT) {
		ANEValue *value =  get_struct_field_value(obj.pointerValue, inter.structDeclareDic[obj.type.typeName], expr.memberName);
		[inter.stack pop];
		[inter.stack push:value];
		return;
		
	}
	
	if (obj.type.typeKind != ANC_TYPE_OBJECT) {
		NSCAssert(0, @"line:%zd, %@ is not object",expr.expr.lineNumber, obj.type.typeName);
	}
	SEL sel = NSSelectorFromString(expr.memberName);
	NSMethodSignature *sig =[_self methodSignatureForSelector:NSSelectorFromString(expr.memberName)];
	void *returnData = malloc([sig methodReturnLength]);
	char *returnTypeEncoding = (char *)[sig methodReturnType];
	returnTypeEncoding = removeTypeEncodingPrefix(returnTypeEncoding);
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setTarget:_self];
	[invocation setSelector:sel];
	[invocation invoke];
	[invocation getReturnValue:returnData];

	ANEValue *retValue = [[ANEValue alloc] initWithCValuePointer:returnData typeEncoding:returnTypeEncoding];
		
	[inter.stack pop];
	[inter.stack push:retValue];
		
}




static ANEValue *invoke(NSUInteger line, id _self, ANCInterpreter *inter, ANEScopeChain *scope, id instance, SEL sel, NSArray<ANCExpression *> *argExprs){
	
	NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
	invocation.target = instance;
	invocation.selector = sel;
	NSUInteger argCount = [sig numberOfArguments];
	for (NSUInteger i = 2; i < argCount; i++) {
	  	char *type = (char *)[sig getArgumentTypeAtIndex:i];
		type = removeTypeEncodingPrefix(type);
		ANCExpression *argExpr = argExprs[i - 2];
		eval_expression(_self, inter, scope, argExpr);
		ANEValue *argValue = [inter.stack pop];
		
		
#define ANANAS_INVOCATION_SET_ARG_CASE(_code, _type, _sel)\
	case _code:{\
		_type value = (_type)argValue._sel;\
		[invocation setArgument:&value atIndex:i];\
		break;\
	}

		
		switch (*type) {
			ANANAS_INVOCATION_SET_ARG_CASE('c', char, c2integerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('s', short, c2integerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('i', int, c2integerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('l', long, c2integerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('q', long long, c2integerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('C', unsigned char, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('S', unsigned short, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('I', unsigned int, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('L', unsigned long, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('Q', unsigned long long, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('B', BOOL, c2uintValue)
			ANANAS_INVOCATION_SET_ARG_CASE('f', float, c2doubleValue)
			ANANAS_INVOCATION_SET_ARG_CASE('d', double, c2doubleValue)
			ANANAS_INVOCATION_SET_ARG_CASE('@', id, c2objectValue)
			ANANAS_INVOCATION_SET_ARG_CASE('#', Class, c2objectValue)
			ANANAS_INVOCATION_SET_ARG_CASE(':', SEL, selValue)
			ANANAS_INVOCATION_SET_ARG_CASE('*', char *, c2pointerValue)
			ANANAS_INVOCATION_SET_ARG_CASE('^', void *, c2pointerValue)
			case '{':{
				void *valuePtr = NULL;
				switch (argValue.type.typeKind) {
					case ANC_TYPE_STRUCT:
						valuePtr = argValue.pointerValue;
						break;
					case ANC_TYPE_STRUCT_LITERAL:{
						size_t structSize= ananas_struct_size_with_encoding(type);
						NSString *structName = ananas_struct_name_with_encoding(type);
						valuePtr = alloca(structSize);
						ananas_struct_data_with_dic(valuePtr, argValue.objectValue, inter.structDeclareDic[structName], inter.structDeclareDic);
					}
					default:
						NSCAssert(0, @"");
						break;
				} ;
				
				[invocation setArgument:valuePtr atIndex:i];
				break;
			}
			default:
				NSCAssert(0, @"line:%zd, ananas not supprot type: %s",argExpr.lineNumber, type);
				break;
		}
		
		
	}
	[invocation invoke];
	
	char *returnType = (char *)[sig methodReturnType];
	returnType = removeTypeEncodingPrefix(returnType);
	void *retValuePointer = alloca([sig methodReturnLength]);
	[invocation getReturnValue:retValuePointer];
	ANEValue *retValue = [[ANEValue alloc] initWithCValuePointer:retValuePointer typeEncoding:returnType];
	return retValue;
}



static void eval_function_call_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCFunctonCallExpression *expr){
	ANCExpressionKind exprKind = expr.expr.expressionKind;
	switch (exprKind) {
		case ANC_IDENTIFIER_EXPRESSION:{
			break;
		}
		case ANC_MEMBER_EXPRESSION:{
			ANCMemberExpression *memberExpr = (ANCMemberExpression *)expr.expr;
			ANCExpression *memberObjExpr = memberExpr.expr;
			SEL sel = NSSelectorFromString(memberExpr.memberName);
			switch (memberObjExpr.expressionKind) {
				case ANC_SELF_EXPRESSION:{
					ANEValue *retValue = invoke(expr.lineNumber, _self, inter, scope, _self, sel, expr.args);
					[inter.stack push:retValue];
					break;
				}
				case ANC_SUPER_EXPRESSION:{
					
					Class superClass = class_getSuperclass([_self class]);
					struct objc_super *superPtr = &(struct objc_super){_self, superClass};
					NSMethodSignature *sig = [_self methodSignatureForSelector:sel];
					NSUInteger argCount = sig.numberOfArguments;
					
					void **args = alloca(sizeof(void *) * argCount);
					ffi_type **argTypes = alloca(sizeof(ffi_type *) * argCount);
					
					argTypes[0] = &ffi_type_pointer;
					args[0] = &superPtr;
					
					argTypes[1] = &ffi_type_pointer;
					args[1] = &sel;
				
					for (NSUInteger i = 2; i < argCount; i++) {
						ANCExpression *argExpr = expr.args[i - 2];
						eval_expression(_self, inter, scope, argExpr);
						ANEValue *argValue = [inter.stack pop];
						char *argTypeEncoding = (char *)[sig getArgumentTypeAtIndex:i];
						argTypeEncoding = removeTypeEncodingPrefix(argTypeEncoding);
						
						
#define ANANAS_SET_FFI_TYPE_AND_ARG_CASE(_code, _type, _ffi_type_value, _sel)\
case _code:{\
argTypes[i] = &_ffi_type_value;\
_type value = (_type)argValue._sel;\
args[i] = &value;\
break;\
}
						
						switch (*argTypeEncoding) {
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('c', char, ffi_type_schar, c2integerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('i', int, ffi_type_sint, c2integerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('s', short, ffi_type_sshort, c2integerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('l', long, ffi_type_slong, c2integerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('q', long long, ffi_type_sint64, c2integerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('C', unsigned char, ffi_type_uchar, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('I', unsigned int, ffi_type_uint, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('S', unsigned short, ffi_type_ushort, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('L', unsigned long, ffi_type_ulong, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('Q', unsigned long long, ffi_type_uint64, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('B', BOOL, ffi_type_sint8, c2uintValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('f', float, ffi_type_float, c2doubleValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('d', double, ffi_type_double, c2doubleValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('@', id, ffi_type_pointer, c2objectValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('#', Class, ffi_type_pointer, c2objectValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE(':', SEL, ffi_type_pointer, selValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('*', char *, ffi_type_pointer, c2pointerValue)
							ANANAS_SET_FFI_TYPE_AND_ARG_CASE('^', id, ffi_type_pointer, c2pointerValue)

							case '{':{
								argTypes[i] = ananas_ffi_type_with_type_encoding(argTypeEncoding);
								args[i] = argValue.pointerValue;
								break;
							}
							
							
							default:
								NSCAssert(0, @"not support type  %s", argTypeEncoding);
								break;
						}
						
					}
					
					char *returnTypeEncoding = (char *)[sig methodReturnType];
					returnTypeEncoding = removeTypeEncodingPrefix(returnTypeEncoding);
					ffi_type *rtype = NULL;
					void *rvalue = NULL;
#define ANANAS_FFI_RETURN_TYPE_CASE(_code, _ffi_type)\
case _code:{\
rtype = &_ffi_type;\
rvalue = alloca(rtype->size);\
break;\
}
					
					switch (*returnTypeEncoding) {
						ANANAS_FFI_RETURN_TYPE_CASE('c', ffi_type_schar)
						ANANAS_FFI_RETURN_TYPE_CASE('i', ffi_type_sint)
						ANANAS_FFI_RETURN_TYPE_CASE('s', ffi_type_sshort)
						ANANAS_FFI_RETURN_TYPE_CASE('l', ffi_type_slong)
						ANANAS_FFI_RETURN_TYPE_CASE('q', ffi_type_sint64)
						ANANAS_FFI_RETURN_TYPE_CASE('C', ffi_type_uchar)
						ANANAS_FFI_RETURN_TYPE_CASE('I', ffi_type_uint)
						ANANAS_FFI_RETURN_TYPE_CASE('S', ffi_type_ushort)
						ANANAS_FFI_RETURN_TYPE_CASE('L', ffi_type_ulong)
						ANANAS_FFI_RETURN_TYPE_CASE('Q', ffi_type_uint64)
						ANANAS_FFI_RETURN_TYPE_CASE('B', ffi_type_sint8)
						ANANAS_FFI_RETURN_TYPE_CASE('f', ffi_type_float)
						ANANAS_FFI_RETURN_TYPE_CASE('d', ffi_type_double)
						ANANAS_FFI_RETURN_TYPE_CASE('@', ffi_type_pointer)
						ANANAS_FFI_RETURN_TYPE_CASE('#', ffi_type_pointer)
						ANANAS_FFI_RETURN_TYPE_CASE(':', ffi_type_pointer)
						ANANAS_FFI_RETURN_TYPE_CASE('^', ffi_type_pointer)
						ANANAS_FFI_RETURN_TYPE_CASE('*', ffi_type_pointer)
						ANANAS_FFI_RETURN_TYPE_CASE('v', ffi_type_void)
						case '{':{
							rtype =ananas_ffi_type_with_type_encoding(returnTypeEncoding);
							rvalue = alloca(rtype->size);
						}
							
						default:
							NSCAssert(0, @"not support type  %s", returnTypeEncoding);
							break;
					}
					
		
					ffi_cif cif;
					ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned int)argCount, rtype, argTypes);
					ffi_call(&cif, objc_msgSendSuper, rvalue, args);
					
					ANEValue *retValue =  [[ANEValue alloc] initWithCValuePointer:rvalue typeEncoding:returnTypeEncoding];
					[inter.stack push:retValue];
					break;
				}
				default:{
					eval_expression(_self, inter, scope, memberObjExpr);
					ANEValue *memberObj = [inter.stack pop];
					ANEValue *retValue = invoke(expr.lineNumber, _self, inter, scope, memberObj, sel, expr.args);
					[inter.stack push:retValue];
					break;
					
					
					
				}
			}
			
			
			break;
		}
		case ANC_FUNCTION_CALL_EXPRESSION:{
			eval_expression(_self, inter, scope, expr.expr);
			ANEValue *blockValue = [inter.stack peekStack:0];
			
			break;
		}
			
		default:
			break;
	}
	
	
	
	
}







static void eval_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope, __kindof ANCExpression *expr){
	switch (expr.expressionKind) {
		case ANC_BOOLEAN_EXPRESSION:
			eval_bool_exprseeion(inter, expr);
			break;
		case ANC_INT_EXPRESSION:
			eval_interger_expression(inter, expr);
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
		case ANC_SUPER_EXPRESSION:
			NSCAssert(0, @"");
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
			eval_struct_expression(_self, inter, scope, expr);
			break;
		case ANC_FUNCTION_CALL_EXPRESSION:
			eval_function_call_expression(_self, inter, scope, expr);
			break;
		default:
			break;
	}
	
}

ANEValue *ane_eval_expression(id _self,ANCInterpreter *inter, ANEScopeChain *scope,ANCExpression *expr){
	eval_expression(_self ,inter, scope, expr);
	return [inter.stack pop];
}

