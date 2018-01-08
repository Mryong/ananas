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
			classDefinition.annotationIfExprResult = value.isTrue ? AnnotationIfExprResultTrue : AnnotationIfExprResultFalse;
			if (!value.isTrue) {
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




#define getter(_type,_value) \
static _type getter_##_type(id _self,SEL sel){\
	NSString *key = NSStringFromSelector(sel);\
	id value = objc_getAssociatedObject(_self,propKey(key));\
return _value;\
}

#define setter(_type,_value,_policy)\
static void setter_##_type##_##_policy(id _self, SEL sel, _type value){\
	NSString *setter = NSStringFromSelector(sel);\
	NSString *firstString = [[setter substringWithRange:NSMakeRange(3, 1)] lowercaseString];\
	NSString *otherString = setter.length > 4 ? [setter substringFromIndex:4] : nil;\
	NSString *key = [NSString stringWithFormat:@"%@%@",firstString, otherString];\
	objc_setAssociatedObject(_self, propKey(key), _value, _policy);\
}

getter(BOOL, [value boolValue])
setter(BOOL,[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(BOOL,[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN)

getter(NSUInteger, [value unsignedIntegerValue])
setter(NSUInteger, [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(NSUInteger, [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN)

getter(NSInteger, [value integerValue])
setter(NSInteger, [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(NSInteger, [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN)

getter(CGFloat, [value cgFloatValue])
setter(CGFloat, [NSNumber numberWithDouble:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGFloat, [NSNumber numberWithDouble:value], OBJC_ASSOCIATION_RETAIN)

typedef long double longDouble;
getter(longDouble, [(NSNumber *)value doubleValue])
setter(longDouble, [NSNumber numberWithDouble:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(longDouble, [NSNumber numberWithDouble:value], OBJC_ASSOCIATION_RETAIN)

typedef const char * cString;
getter(cString, [value UTF8String])
setter(cString, [NSString stringWithUTF8String:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(cString, [NSString stringWithUTF8String:value], OBJC_ASSOCIATION_RETAIN)

getter(Class, value)
setter(Class, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(Class, value, OBJC_ASSOCIATION_RETAIN)
setter(Class, value, OBJC_ASSOCIATION_ASSIGN)
setter(Class, value, OBJC_ASSOCIATION_COPY_NONATOMIC)
setter(Class, value, OBJC_ASSOCIATION_COPY)

getter(SEL, NSSelectorFromString(value))
setter(SEL, NSStringFromSelector(sel),OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(SEL, NSStringFromSelector(sel),OBJC_ASSOCIATION_RETAIN)

getter(id, value)
setter(id, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(id, value, OBJC_ASSOCIATION_RETAIN)
setter(id, value, OBJC_ASSOCIATION_ASSIGN)
setter(id, value, OBJC_ASSOCIATION_COPY_NONATOMIC)
setter(id, value, OBJC_ASSOCIATION_COPY)

getter(CGRect, [value CGRectValue])
setter(CGRect, [NSValue valueWithCGRect:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGRect, [NSValue valueWithCGRect:value],OBJC_ASSOCIATION_RETAIN)

getter(CGSize, [value CGSizeValue])
setter(CGSize, [NSValue valueWithCGSize:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGSize, [NSValue valueWithCGSize:value],OBJC_ASSOCIATION_RETAIN)

getter(CGPoint, [value CGPointValue])
setter(CGPoint, [NSValue valueWithCGPoint:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGPoint, [NSValue valueWithCGPoint:value],OBJC_ASSOCIATION_RETAIN)

getter(CGAffineTransform, [value CGAffineTransformValue])
setter(CGAffineTransform, [NSValue valueWithCGAffineTransform:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGAffineTransform, [NSValue valueWithCGAffineTransform:value],OBJC_ASSOCIATION_RETAIN)

getter(NSRange, [value rangeValue])
setter(NSRange, [NSValue valueWithRange:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(NSRange, [NSValue valueWithRange:value],OBJC_ASSOCIATION_RETAIN)

getter(CGVector, [value CGVectorValue])
setter(CGVector, [NSValue valueWithCGVector:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CGVector, [NSValue valueWithCGVector:value],OBJC_ASSOCIATION_RETAIN)

getter(UIOffset, [value UIOffsetValue])
setter(UIOffset, [NSValue valueWithUIOffset:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(UIOffset, [NSValue valueWithUIOffset:value],OBJC_ASSOCIATION_RETAIN)

getter(UIEdgeInsets, [value UIEdgeInsetsValue])
setter(UIEdgeInsets, [NSValue valueWithUIEdgeInsets:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(UIEdgeInsets, [NSValue valueWithUIEdgeInsets:value],OBJC_ASSOCIATION_RETAIN)

getter(CATransform3D, [value CATransform3DValue])
setter(CATransform3D, [NSValue valueWithCATransform3D:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(CATransform3D, [NSValue valueWithCATransform3D:value],OBJC_ASSOCIATION_RETAIN)

typedef void * unknownType;
getter(unknownType, [value pointerValue])
setter(unknownType, [NSValue valueWithPointer:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)
setter(unknownType, [NSValue valueWithPointer:value],OBJC_ASSOCIATION_RETAIN)








#define getter_setter_base_type(_type,_encodeing) \
switch (prop.modifier & ANCPropertyModifierMemMask) {\
	case ANCPropertyModifierMemStrong:{\
		NSCAssert(0, @ #_type " type can not use strong");\
		break;\
	}\
	case ANCPropertyModifierMemWeak:{\
		NSCAssert(0, @ #_type " type can not use weak");\
		break;\
	}\
	case ANCPropertyModifierMemCopy:{\
		NSCAssert(0, @ #_type " type can not use copy");\
		break;\
	}\
	case ANCPropertyModifierMemAssign:{\
			class_replaceMethod(clazz, getterSEL, (IMP)getter_##_type, #_encodeing"@:");\
		if ((prop.modifier & ANCPropertyModifierAtomicMask) == ANCPropertyModifierAtomic) {\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_RETAIN, "v@:"#_encodeing);\
		}else{\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_RETAIN_NONATOMIC, "v@:"#_encodeing);\
		}\
		break;\
	}\
	default:\
		break;\
}

#define getter_setter_oc_type(_type,_encodeing) \
switch (prop.modifier & ANCPropertyModifierMemMask) {\
		class_replaceMethod(clazz, getterSEL, (IMP)getter_##_type, #_encodeing"@:");\
	case ANCPropertyModifierMemStrong:{\
		if ((prop.modifier & ANCPropertyModifierAtomicMask) == ANCPropertyModifierAtomic) {\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_RETAIN, "v@:"#_encodeing);\
		}else{\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_RETAIN_NONATOMIC, "v@:"#_encodeing);\
		}\
		break;\
	}\
	case ANCPropertyModifierMemAssign:\
	case ANCPropertyModifierMemWeak:{\
		class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_ASSIGN, "v@:"#_encodeing);\
	}\
	case ANCPropertyModifierMemCopy:{\
		if ((prop.modifier & ANCPropertyModifierAtomicMask) == ANCPropertyModifierAtomic) {\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_COPY, "v@:"#_encodeing);\
		}else{\
			class_replaceMethod(clazz, setterSEL, (IMP)setter_##_type##_OBJC_ASSOCIATION_COPY_NONATOMIC, "v@:"#_encodeing);\
		}\
		break;\
	}\
	default:\
		break;\
}


static void replace_getter_setter_method(Class clazz, ANCPropertyDefinition *prop){
	SEL getterSEL = NSSelectorFromString(prop.name);
	NSString *str1 = [[prop.name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
	NSString *str2 = prop.name.length > 1 ? [prop.name substringFromIndex:1] : nil;
	SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
	switch (prop.typeSpecifier.typeKind) {
		case ANC_TYPE_BOOL:{
			getter_setter_base_type(BOOL, B)
			break;
		}
		case ANC_TYPE_NS_U_INTEGER:{
			getter_setter_base_type(NSUInteger, Q)
			break;
		}
		case ANC_TYPE_NS_INTEGER:{
			getter_setter_base_type(NSInteger, q)
			break;
		}
		case ANC_TYPE_CG_FLOAT:{
			getter_setter_base_type(CGFloat, d)
			break;
		}
		case ANC_TYPE_DOUBLE:{
			getter_setter_base_type(longDouble, D)
			break;
		}
		case ANC_TYPE_STRING:{
			getter_setter_base_type(cString, *)
			break;
		}
		case ANC_TYPE_SEL:{
			getter_setter_base_type(SEL, :)
			break;
		}
		case ANC_TYPE_UNKNOWN:{
			getter_setter_base_type(unknownType, ^v)
			break;
		}
		case ANC_TYPE_CLASS:{
			getter_setter_oc_type(Class, #)
			break;
		}
		case ANC_TYPE_ANANAS_BLOCK:{
			getter_setter_oc_type(id, ?@)
			break;
		}
		case ANC_TYPE_NS_OBJECT:{
			getter_setter_oc_type(id, @)
			break;
		}


		case ANC_TYPE_STRUCT:{
			 NSString *structName = prop.typeSpecifier.identifer;
			
			if ([structName isEqualToString:@"CGRect"]) {
				getter_setter_base_type(CGRect, {CGRect={CGPoint=dd}{CGSize=dd}})
				break;
			}
			
			if ([structName isEqualToString:@"CGSzie"]) {
				getter_setter_base_type(CGSize, {CGSize=dd})
				break;
			}
			
			if ([structName isEqualToString:@"CGPoint"]) {
				getter_setter_base_type(CGPoint, {CGPoint=dd})
				break;
			}
			
			if ([structName isEqualToString:@"CGAffineTransform"]) {
				getter_setter_base_type(CGAffineTransform, {CGAffineTransform=dddddd})
				break;
			}
			
			if ([structName isEqualToString:@"NSRange"]) {
				getter_setter_base_type(NSRange, {_NSRange=QQ})
				break;
			}
			
			if ([structName isEqualToString:@"CGVector"]) {
				getter_setter_base_type(CGVector, {CGVector=dd})
				break;
			}
			
			if ([structName isEqualToString:@"UIOffset"]) {
				getter_setter_base_type(UIOffset, {UIOffset=dd})
				break;
			}
			
			if ([structName isEqualToString:@"UIEdgeInsets"]) {
				getter_setter_base_type(UIEdgeInsets, {UIEdgeInsets=dddd})
				break;
			}
			if ([structName isEqualToString:@"CATransform3D"]) {
				getter_setter_base_type(CATransform3D, {CATransform3D=dddddddddddddddd})
				break;
			}
		}
			
		default:
			NSCAssert(0, @"not supper property type: %@", prop.name);
			break;
	}
	
}





static void replace_prop(Class clazz, ANCPropertyDefinition *prop){
	NSNumber *i;
	[i doubleValue];
	
	NSString *t = prop.typeSpecifier.typeEncoding;
	if ([t isEqualToString:@"@"]) {
		t = [NSString stringWithFormat:@"@\"%@\"",prop.typeSpecifier.identifer];
	}
	objc_property_attribute_t type = {"T", t.UTF8String};
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
	
	replace_getter_setter_method(clazz, prop);
	
	
}

static NSString *fix_type_encoding(ANCInterpreter *interpreter,ANCTypeSpecifier *type){
	if (![type.typeEncoding isEqualToString:@"v^"]) {
		return type.typeEncoding;
	}
	
	NSString *identifer = type.identifer;
	ANCStructDeclare *structdeclare = interpreter.structDeclareDic[identifer];
	if (!structdeclare) {
		return type.typeEncoding;
	}
	
	type.typeEncoding = structdeclare.typeEncoding;
	return type.typeEncoding;
	
	
	
	
}





static void ananas_forward_invocation(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation)
{
	
	
	
	NSLog(@"");
}

static void replace_method(ANCInterpreter *interpreter,Class clazz, ANCMethodDefinition *method){
	ANCFunctionDefinition *func = method.functionDefinition;
	fix_type_encoding(interpreter, func.returnTypeSpecifier);
	for (ANCParameter *param in func.params) {
		fix_type_encoding(interpreter, param.type);
	}
	
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
		NSMutableString *tempTypeEncoding = [NSMutableString stringWithString:func.returnTypeSpecifier.typeEncoding];
		for (ANCParameter *param in func.params) {
			[tempTypeEncoding appendString:param.type.typeEncoding];
		}
		typeEncoding = tempTypeEncoding.UTF8String;
	}
	Class c2 = method.classMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
	class_replaceMethod(c2, @selector(forwardInvocation:), (IMP)ananas_forward_invocation,"v@:@");
	class_replaceMethod(c2, sel, _objc_msgForward, typeEncoding);
}


static void fix_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	Class clazz = NSClassFromString(classDefinition.name);
	for (ANCPropertyDefinition *prop in classDefinition.properties) {
		replace_prop(clazz, prop);
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
