//
//  execute.m
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ananasc.h"
#import "execute.h"
#import "ANEEnvironment.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "util.h"
#import "ffi.h"
#import "ANANASMethodMapTable.h"

static NSMutableDictionary *_propKeys;
static const void *propKey(NSString *propName) {
	if (!_propKeys) _propKeys = [[NSMutableDictionary alloc] init];
	id key = _propKeys[propName];
	if (!key) {
		key = [propName copy];
		[_propKeys setObject:key forKey:propName];
	}
	return (__bridge const void *)(key);
}


static ANEValue *default_value_with_type_specifier(ANCInterpreter *inter, ANCTypeSpecifier *typeSpecifier){
	ANEValue *value = [[ANEValue alloc] init];
	value.type = typeSpecifier;
	if (typeSpecifier.typeKind == ANC_TYPE_STRUCT) {
		 size_t size = ananas_struct_size_with_encoding([typeSpecifier typeEncoding]);
		value.pointerValue = malloc(size);
	}
	return value;
}


static void add_variable(ANEScopeChain *scope, NSString *name, ANEValue *value){
	ANEVariable *var = [[ANEVariable alloc] init];
	var.name = name;
	var.value = value;
	[scope.vars addObject:var];
}

static void execute_declaration(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, ANCDeclaration *declaration){
	ANEValue *value;
	if (declaration.initializer) {
		value = ane_eval_expression(_self, inter, scope, declaration.initializer);
	}else{
		value = default_value_with_type_specifier(inter, declaration.type);
	}
	add_variable(scope, declaration.name, value);
}





static ANEStatementResult *execute_else_if_list(id _self ,ANCInterpreter *inter, ANEScopeChain *scope,NSArray<ANCElseIf *> *elseIfList,BOOL *executed){
	ANEStatementResult *res;
	*executed = NO;
	for (ANCElseIf *elseIf in elseIfList) {
		ANEValue *conValue = ane_eval_expression(_self, inter, scope, elseIf.condition);
		if ([conValue isSubtantial]) {
			ANEScopeChain *conScope = [ANEScopeChain scopeChainWithNext:scope];
			res = ane_execute_statement_list(_self, inter, conScope, elseIf.thenBlock.statementList);
			*executed = YES;
			break;
		}
	}
	return res ?: [ANEStatementResult normalResult];
}

static ANEStatementResult *execute_if_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, ANCIfStatement *statement){
	ANEStatementResult *res;
	ANEValue *conValue = ane_eval_expression(_self, inter, scope, statement.condition);
	if ([conValue isSubtantial]) {
		ANEScopeChain *conScope = [ANEScopeChain scopeChainWithNext:scope];
		res = ane_execute_statement_list(_self, inter, conScope, statement.thenBlock.statementList);
	}else{
		BOOL executed;
		res = execute_else_if_list(_self, inter, scope, statement.elseIfList, &executed);
		if (!executed && statement.elseBlocl) {
			ANEScopeChain *elseScope = [ANEScopeChain scopeChainWithNext:scope];
			res = ane_execute_statement_list(_self, inter, elseScope, statement.elseBlocl.statementList);
		}
	}
	return res ?: [ANEStatementResult normalResult];
	
}


static ANEStatementResult *execute_switch_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, ANCSwitchStatement *statement){
	ANEStatementResult *res;
	ANEValue *value = ane_eval_expression(_self, inter, scope, statement.expr);
	BOOL hasMatch = NO;
	for (ANCCase *case_ in statement.caseList) {
		if (!hasMatch) {
			ANEValue *caseValue = ane_eval_expression(_self, inter, scope, case_.expr);
			BOOL equal = ananas_equal_value(case_.expr.lineNumber, value, caseValue);
			if (equal) {
				hasMatch = YES;
			}else{
				continue;
			}
		}
		ANEScopeChain *caseScope = [ANEScopeChain scopeChainWithNext:scope];
		res = ane_execute_statement_list(_self, inter, caseScope, case_.block.statementList);
		if (res.type != ANEStatementResultTypeNormal) {
			break;
		}
	}
	res = res ?: [ANEStatementResult normalResult];
	if (res.type == ANEStatementResultTypeNormal) {
		ANEScopeChain *defaultCaseScope = [ANEScopeChain scopeChainWithNext:scope];
		res = ane_execute_statement_list(_self, inter, defaultCaseScope, statement.defaultBlock.statementList);
	}
	
	if (res.type == ANEStatementResultTypeBreak) {
		res.type = ANEStatementResultTypeNormal;
	}
	
	return res;
}



static ANEStatementResult *execute_for_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, ANCForStatement *statement){
	ANEStatementResult *res;
	ANEScopeChain *forScope = [ANEScopeChain scopeChainWithNext:scope];
	if (statement.initializerExpr) {
		ane_eval_expression(_self, inter, forScope, statement.initializerExpr);
	}else if (statement.declaration){
		execute_declaration(_self, inter, forScope, statement.declaration);
	}
	
	for (;;) {
		ANEValue *conValue = ane_eval_expression(_self, inter, forScope, statement.condition);
		if (![conValue isSubtantial]) {
			break;
		}
		res = ane_execute_statement_list(_self, inter, forScope, statement.block.statementList);
		if (res.type == ANEStatementResultTypeReturn) {
			break;
		}else if (res.type == ANEStatementResultTypeBreak) {
			res.type = ANEStatementResultTypeNormal;
			break;
		}else if (res.type == ANEStatementResultTypeContinue){
			res.type = ANEStatementResultTypeNormal;
		}
		if (statement.post) {
			ane_eval_expression(_self, inter, forScope, statement.post);
		}
		
	}
	
	return res ?: [ANEStatementResult normalResult];
	
}


static ANEStatementResult *execute_for_each_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, ANCForEachStatement *statement){
	ANEStatementResult *res;
	ANEScopeChain *forScope = [ANEScopeChain scopeChainWithNext:scope];

	if (statement.declaration) {
		execute_declaration(_self, inter, forScope, statement.declaration);
		ANCIdentifierExpression *identifierExpr = [[ANCIdentifierExpression alloc] init];
		identifierExpr.expressionKind = ANC_IDENTIFIER_EXPRESSION;
		identifierExpr.identifier = statement.declaration.name;
		statement.identifierExpr = identifierExpr;
	}
	
	
	
	ANEValue *arrValue = ane_eval_expression(_self, inter, scope, statement.arrayExpr);
	if (arrValue.type.typeKind != ANC_TYPE_OBJECT) {
		NSCAssert(0, @"");
	}
	
	for (id var in arrValue.objectValue) {
		ANEValue *operValue = [[ANEValue alloc] init];
		operValue.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
		operValue.objectValue = var;
		ananas_assign_value_to_identifer_expr(_self, inter, scope, statement.identifierExpr, operValue);
		
		res = ane_execute_statement_list(_self, inter, forScope, statement.block.statementList);
		if (res.type == ANEStatementResultTypeReturn) {
			break;
		}else if (res.type == ANEStatementResultTypeBreak) {
			res.type = ANEStatementResultTypeNormal;
			break;
		}else if (res.type == ANEStatementResultTypeContinue){
			res.type = ANEStatementResultTypeNormal;
		}
	}
	return res ?: [ANEStatementResult normalResult];
	
}

static ANEStatementResult *execute_while_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope,  ANCWhileStatement *statement){
	ANEStatementResult *res;
	ANEScopeChain *whileScope = [ANEScopeChain scopeChainWithNext:scope];
	for (;;) {
		ANEValue *conValue = ane_eval_expression(_self, inter, whileScope, statement.condition);
		if (![conValue isSubtantial]) {
			break;
		}
		res = ane_execute_statement_list(_self, inter, whileScope, statement.block.statementList);
		if (res.type == ANEStatementResultTypeReturn) {
			break;
		}else if (res.type == ANEStatementResultTypeBreak) {
			res.type = ANEStatementResultTypeNormal;
			break;
		}else if (res.type == ANEStatementResultTypeContinue){
			res.type = ANEStatementResultTypeNormal;
		}
	}
	return res ?: [ANEStatementResult normalResult];
}

static ANEStatementResult *execute_do_while_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope,  ANCDoWhileStatement *statement){
	ANEStatementResult *res;
	ANEScopeChain *whileScope = [ANEScopeChain scopeChainWithNext:scope];
	for (;;) {
		res = ane_execute_statement_list(_self, inter, whileScope, statement.block.statementList);
		if (res.type == ANEStatementResultTypeReturn) {
			break;
		}else if (res.type == ANEStatementResultTypeBreak) {
			res.type = ANEStatementResultTypeNormal;
			break;
		}else if (res.type == ANEStatementResultTypeContinue){
			res.type = ANEStatementResultTypeNormal;
		}
		ANEValue *conValue = ane_eval_expression(_self, inter, whileScope, statement.condition);
		if (![conValue isSubtantial]) {
			break;
		}
	}
	return res ?: [ANEStatementResult normalResult];
}



static ANEStatementResult *execute_return_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope,  ANCReturnStatement *statement){
	ANEStatementResult *res = [ANEStatementResult returnResult];
	if (statement.retValExpr) {
		res.reutrnValue = ane_eval_expression(_self, inter, scope, statement.retValExpr);
	}else{
		res.reutrnValue = [ANEValue voidValueInstance];
	}
	return res;
}


static ANEStatementResult *execute_break_statement(){
	return [ANEStatementResult breakResult];
}


static ANEStatementResult *execute_continue_statement(){
	return [ANEStatementResult continueResult];
}



static  ANEStatementResult *execute_statement(id _self ,ANCInterpreter *inter, ANEScopeChain *scope, __kindof ANCStatement *statement){
	ANEStatementResult *res;
	switch (statement.kind) {
		case ANCStatementKindExpression:
			ane_eval_expression(_self ,inter, scope, [(ANCExpressionStatement *)statement expr]);
			res = [ANEStatementResult normalResult];
			break;
		case ANCStatementKindDeclaration:{
			execute_declaration(_self, inter, scope, [(ANCDeclarationStatement *)statement declaration]);
			res = [ANEStatementResult normalResult];
			break;
		}
		case ANCStatementKindIf:{
			res = execute_if_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindSwitch:{
			res = execute_switch_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindFor:{
			res = execute_for_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindForEach:{
			res = execute_for_each_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindWhile:{
			res = execute_while_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindDoWhile:{
			res = execute_do_while_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindReturn:{
			res = execute_return_statement(_self, inter, scope, statement);
			break;
		}
		case ANCStatementKindBreak:{
			res = execute_break_statement();
			break;
		}
		case ANCStatementKindContinue:{
			res = execute_continue_statement();
			break;
		}
			
		default:
			break;
	}
	return res;
}


ANEStatementResult *ane_execute_statement_list(id _self, ANCInterpreter *inter, ANEScopeChain *scope, NSArray<ANCStatement *> *statementList){
	ANEStatementResult *result;
	if (statementList.count) {
		for (ANCStatement *statement in statementList) {
			result = execute_statement(_self,inter, scope, statement);
			if (result.type != ANEStatementResultTypeNormal) {
				break;
			}
		}
	}else{
		result = [ANEStatementResult normalResult];
	}
	return result;
}


ANEValue * ananas_call_ananas_function(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCFunctionDefinition *func, NSArray<ANEValue *> *args){
	NSArray<ANCParameter *> *params = func.params;
	if (params.count != args.count) {
		NSCAssert(0, @"");
	}
	ANEScopeChain *funScope = [ANEScopeChain scopeChainWithNext:scope];
	NSUInteger i = 0;
	for (ANCParameter *param in params) {
		add_variable(funScope, param.name, args[i]);
		i++;
	}
	
	ANEStatementResult *res = ane_execute_statement_list(_self, inter, funScope, func.block.statementList);
	if (res.type == ANEStatementResultTypeReturn) {
		return res.reutrnValue;
	}else{
		return [ANEValue voidValueInstance];
	}
}


static void define_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	if (classDefinition.annotationIfExprResult == AnnotationIfExprResultNoComputed) {
		ANCExpression *annotationIfConditionExpr = classDefinition.annotationIfConditionExpr;
		if (annotationIfConditionExpr) {
			ANEValue *value = ane_eval_expression(nil ,interpreter, interpreter.topScope, annotationIfConditionExpr);
			classDefinition.annotationIfExprResult = value.isSubtantial ? AnnotationIfExprResultTrue : AnnotationIfExprResultFalse;
			if (!value.isSubtantial) {
				return;
			}
		}else{
			classDefinition.annotationIfExprResult = AnnotationIfExprResultTrue;
		}
	}
	
	
	if (classDefinition.annotationIfExprResult != AnnotationIfExprResultTrue) {
		return;
	}
	
	Class clazz = NSClassFromString(classDefinition.name);
	if (!clazz) {
		NSString *superClassName = classDefinition.superNmae;
		Class superClass = NSClassFromString(superClassName);
		if (!superClass) {
			define_class(interpreter, interpreter.classDefinitionDic[superClassName]);
		}
		
		if (!superClass) {
			NSCAssert(0, @"not found super class: %@",classDefinition.name);
			return;
		}
		Class clazz = objc_allocateClassPair(superClass, classDefinition.name.UTF8String, 0);
		objc_registerClassPair(clazz);
	}else{
		Class superClass = class_getSuperclass(clazz);
		char const *superClassName = class_getName(superClass);
		if (strcmp(classDefinition.superNmae.UTF8String, superClassName)) {
			NSCAssert(0, @"类 %@ 在ananas中与OC中父类名称不一致,ananas:%@ OC:%s ",classDefinition.name,classDefinition.superNmae, superClassName);
			return;
		}
	}
}




void getterInter(ffi_cif *cif, void *ret, void **args, void *userdata){
	

}


void setterInter(ffi_cif *cif, void *ret, void **args, void *userdata){
	
	
}
static void replace_getter_method(ANCInterpreter *inter ,Class clazz, ANCPropertyDefinition *prop){
	SEL getterSEL = NSSelectorFromString(prop.name);
	const char *prtTypeEncoding  = [prop.typeSpecifier typeEncoding];
	ffi_type *returnType = &ffi_type_void;
	unsigned int argCount = 2;
	ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
	argTypes[0] = &ffi_type_pointer;
	argTypes[1] = &ffi_type_pointer;

	ffi_cif cif;
	ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argCount, returnType, argTypes);

	void *imp = NULL;
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	ffi_prep_closure_loc(closure, &cif, getterInter, (__bridge_retained void *)prop, getterInter);
	class_replaceMethod(clazz, getterSEL, (IMP)imp, ananas_str_append(prtTypeEncoding, "@:"));

	
}

static void replace_setter_method(ANCInterpreter *inter ,Class clazz, ANCPropertyDefinition *prop){
	NSString *str1 = [[prop.name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
	NSString *str2 = prop.name.length > 1 ? [prop.name substringFromIndex:1] : nil;
	SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
	const char *prtTypeEncoding  = [prop.typeSpecifier typeEncoding];
	ffi_type *returnType = &ffi_type_void;
	unsigned int argCount = 3;
	ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
	argTypes[0] = &ffi_type_pointer;
	argTypes[1] = &ffi_type_pointer;
	argTypes[2] = ananas_ffi_type_with_type_encoding([prop.typeSpecifier typeEncoding]);
	if (argTypes[2] == NULL) {
		NSCAssert(0, @"");
	}
	
	ffi_cif cif;
	ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argCount, returnType, argTypes);
	
	void *imp = NULL;
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	ffi_prep_closure_loc(closure, &cif, getterInter, (__bridge_retained void *)prop, setterInter);
	class_replaceMethod(clazz, setterSEL, (IMP)imp, ananas_str_append("v@:", prtTypeEncoding));
	
	
	

	
}



static void replace_prop(ANCInterpreter *inter ,Class clazz, ANCPropertyDefinition *prop){
	if (prop.annotationIfConditionExpr) {
		ANEValue *conValue = ane_eval_expression(nil, inter, inter.topScope, prop.annotationIfConditionExpr);
		if (![conValue isSubtantial]) {
			return;
		}
	}
	
	objc_property_attribute_t type = {"T", [prop.typeSpecifier typeEncoding]};
	objc_property_attribute_t memAttr = {"",""};
	switch (prop.modifier & ANCPropertyModifierMemMask) {
		case ANCPropertyModifierMemStrong:
			memAttr.name = "&";
			break;
		case ANCPropertyModifierMemWeak:
			memAttr.name = "W";
			break;
		case ANCPropertyModifierMemCopy:
			memAttr.name = "C";
			break;
		default:
			break;
	}
	
	objc_property_attribute_t atomicAttr = {"",""};
	switch (prop.modifier & ANCPropertyModifierAtomicMask) {
		case ANCPropertyModifierAtomic:
			break;
		case ANCPropertyModifierNonatomic:
			atomicAttr.name = "N";
			break;
		default:
			break;
	}
	objc_property_attribute_t attrs[] = { type, memAttr, atomicAttr };
	class_replaceProperty(clazz, prop.name.UTF8String, attrs, 3);
	
	replace_getter_method(inter, clazz, prop);
	replace_setter_method(inter, clazz, prop);
	
}







static void ananas_forward_invocation(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation)
{
	
	 BOOL classMethod = object_isClass(assignSlf);
	ANANASMethodMapTableItem *map = [[ANANASMethodMapTable shareInstance] getMethodMapTableItemWith:classMethod ? assignSlf : [assignSlf class] classMethod:classMethod sel:selector];
	ANCMethodDefinition *method = map.method;
	ANCInterpreter *inter = map.inter;
	
	ANEScopeChain *classScope = [ANEScopeChain scopeChainWithNext:inter.topScope];
	classScope.instance = assignSlf;
	
	NSMutableArray<ANEValue *> *args = [NSMutableArray array];
	[args addObject:[ANEValue valueInstanceWithObject:assignSlf]];
	[args addObject:[ANEValue valueInstanceWithSEL:selector]];
	NSMethodSignature *methodSignature = [invocation methodSignature];
	NSUInteger numberOfArguments = [methodSignature numberOfArguments];
	for (NSUInteger i = 2; i < numberOfArguments; i++) {
		const char *typeEncoding = [methodSignature getArgumentTypeAtIndex:i];
		size_t size = ananas_size_with_encoding(typeEncoding);
		void *ptr = malloc(size);
		[invocation getArgument:ptr atIndex:i];
		ANEValue *argValue = [[ANEValue alloc] initWithCValuePointer:ptr typeEncoding:typeEncoding];
		[args addObject:argValue];
	}
	
	ANEValue *retValue = ananas_call_ananas_function(assignSlf, inter, classScope, method.functionDefinition, args);
	size_t retLen = [methodSignature methodReturnLength];
	void *retPtr = malloc(retLen);
	const char *retTypeEncoding = [methodSignature methodReturnType];
	[retValue assign2CValuePointer:retPtr typeEncoding:retTypeEncoding];
	[invocation setReturnValue:retPtr];
}

static void replace_method(ANCInterpreter *interpreter,Class clazz, ANCMethodDefinition *method){
	if (method.annotationIfConditionExpr) {
		ANEValue *conValue = ane_eval_expression(nil, interpreter, interpreter.topScope, method.annotationIfConditionExpr);
		if (![conValue isSubtantial]) {
			return;
		}
	}
	ANCFunctionDefinition *func = method.functionDefinition;
	SEL sel = NSSelectorFromString(func.name);
	
	ANANASMethodMapTableItem *item = [[ANANASMethodMapTableItem alloc] initWithClass:clazz inter:interpreter method:method];
	[[ANANASMethodMapTable shareInstance] addMethodMapTableItem:item];
	
	
	
	const char *typeEncoding;
	Method ocMethod;
	if (method.classMethod) {
		ocMethod = class_getClassMethod(clazz, sel);
	}else{
		ocMethod = class_getInstanceMethod(clazz, sel);
	}
	
	if (ocMethod) {
		typeEncoding = method_getTypeEncoding(ocMethod);
	}else{
		typeEncoding =[func.returnTypeSpecifier typeEncoding];
		
		for (ANCParameter *param in func.params) {
			const char *paramTypeEncoding = [param.type typeEncoding];
			typeEncoding = ananas_str_append(typeEncoding, paramTypeEncoding);
		}
	}
	Class c2 = method.classMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
	class_replaceMethod(c2, @selector(forwardInvocation:), (IMP)ananas_forward_invocation,"v@:@");
	class_replaceMethod(c2, sel, _objc_msgForward, typeEncoding);
}


static void fix_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	Class clazz = NSClassFromString(classDefinition.name);
	for (ANCPropertyDefinition *prop in classDefinition.properties) {
		
		replace_prop(interpreter,clazz, prop);
	}
	
	for (ANCMethodDefinition *classMethod in classDefinition.classMethods) {
		replace_method(interpreter, clazz, classMethod);
	}
	
	for (ANCMethodDefinition *instanceMethod in classDefinition.instanceMethods) {
		replace_method(interpreter, clazz, instanceMethod);
	}
	
}

void add_struct_declare(ANCStructDeclare *structDeclaer){
	
}



void ane_interpret(ANCInterpreter *interpreter){
	
	for (__kindof NSObject *top in interpreter.topList) {
		if ([top isKindOfClass:[ANCStatement class]]) {
			execute_statement(nil, interpreter, interpreter.topScope, top);
		}else if ([top isKindOfClass:[ANCStructDeclare class]]){
			add_struct_declare(top);
		}else if ([top isKindOfClass:[ANCClassDefinition class]]){
			define_class(interpreter, top);
			fix_class(interpreter,top);
		}
	}
	
	
}
