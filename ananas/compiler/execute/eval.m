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
static void eval_plus_expression(id _self, ANCInterpreter *inter, ANEScopeChain *scope,ANCBinaryExpression  *expr){
	
	
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

