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


static  ANEStatementResult *execute_statement(ANCInterpreter *inter, ANEScopeChain *scope, ANCStatement *statement){
	ANEStatementResult *res;
	switch (statement.kind) {
		case ANCStatementKindExpression:
			ane_eval_expression(nil ,inter, scope, [(ANCExpressionStatement *)statement expr]);
			break;
		
			
		default:
			break;
	}
	return res;
}


ANEStatementResult *ane_execute_statement_list(ANCInterpreter *inter, ANEScopeChain *scope, NSArray<ANCStatement *> *statementList){
	ANEStatementResult *result;
	if (statementList.count) {
		for (ANCStatement *statement in statementList) {
			result = execute_statement(inter, scope, statement);
			if (result.type != ANEStatementResultTypeNormal) {
				break;
			}
		}
	}else{
		result = [[ANEStatementResult alloc] init];
		result.type = ANEStatementResultTypeNormal;
	}
	return result;
}


static void define_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	if (classDefinition.annotationIfExprResult == AnnotationIfExprResultNoComputed) {
		ANCExpression *annotationIfConditionExpr = classDefinition.annotationIfConditionExpr;
		if (annotationIfConditionExpr) {
			ANEValue *value = ane_eval_expression(nil ,interpreter, nil, annotationIfConditionExpr);
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
	const char *prtTypeEncoding  = [prop.typeSpecifier typeEncodingWithInterpreter:inter];
	ffi_type *returnType = &ffi_type_void;
	unsigned int argCount = 2;
	ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
	argTypes[0] = &ffi_type_pointer;
	argTypes[1] = &ffi_type_pointer;

	ffi_cif cif;
	ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argCount, returnType, argTypes);

	void *imp;
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	ffi_prep_closure_loc(closure, &cif, getterInter, (__bridge_retained void *)prop, getterInter);
	class_replaceMethod(clazz, getterSEL, (IMP)imp, ananas_strappend(prtTypeEncoding, "@:"));

	
}

static void replace_setter_method(ANCInterpreter *inter ,Class clazz, ANCPropertyDefinition *prop){
	NSString *str1 = [[prop.name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
	NSString *str2 = prop.name.length > 1 ? [prop.name substringFromIndex:1] : nil;
	SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
	const char *prtTypeEncoding  = [prop.typeSpecifier typeEncodingWithInterpreter:inter];
	ffi_type *returnType = &ffi_type_void;
	unsigned int argCount = 3;
	ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
	argTypes[0] = &ffi_type_pointer;
	argTypes[1] = &ffi_type_pointer;
	argTypes[2] = ananas_ffi_type_with_type_encoding([prop.typeSpecifier typeEncodingWithInterpreter:inter]);
	if (argTypes[2] == NULL) {
		NSCAssert(0, @"");
	}
	
	ffi_cif cif;
	ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argCount, returnType, argTypes);
	
	void *imp;
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	ffi_prep_closure_loc(closure, &cif, getterInter, (__bridge_retained void *)prop, setterInter);
	class_replaceMethod(clazz, setterSEL, (IMP)imp, ananas_strappend("v@:", prtTypeEncoding));
	
	
	

	
}



static void replace_prop(ANCInterpreter *inter ,Class clazz, ANCPropertyDefinition *prop){
	
	objc_property_attribute_t type = {"T", [prop.typeSpecifier typeEncodingWithInterpreter:inter]};
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
	
	
	
	NSLog(@"");
}

static void replace_method(ANCInterpreter *interpreter,Class clazz, ANCMethodDefinition *method){
	ANCFunctionDefinition *func = method.functionDefinition;
	
	SEL sel = NSSelectorFromString(func.name);
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
		typeEncoding =[func.returnTypeSpecifier typeEncodingWithInterpreter:interpreter];
		
		for (ANCParameter *param in func.params) {
			const char *paramTypeEncoding = [param.type typeEncodingWithInterpreter:interpreter];
			typeEncoding = ananas_strappend(typeEncoding, paramTypeEncoding);
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

void add_struct_declare(){
	
}



void ane_interpret(ANCInterpreter *interpreter){
	
	for (__kindof NSObject *top in interpreter.topList) {
		if ([top isKindOfClass:[ANCStatement class]]) {
			ANEStatementResult *result = execute_statement(interpreter, interpreter.topScope, top);
		}else if ([top isKindOfClass:[ANCStructDeclare class]]){
			add_struct_declare();
		}else if ([top isKindOfClass:[ANCClassDefinition class]]){
			define_class(interpreter, top);
			fix_class(interpreter,top);
		}
	}
	
	
}
