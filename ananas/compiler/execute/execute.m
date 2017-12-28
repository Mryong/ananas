//
//  execute.m
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ananasc.h"
#import "execute.h"
#import "ANEValue.h"
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


void execute_statement(){
	
}

static void define_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	if (classDefinition.annotationIfExprResult == AnnotationIfExprResultNoComputed) {
		ANCExpression *annotationIfConditionExpr = classDefinition.annotationIfConditionExpr;
		if (annotationIfConditionExpr) {
			ANEValue *value = ane_eval_expression(interpreter, nil, annotationIfConditionExpr);
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
		if (!strcmp(classDefinition.superNmae.UTF8String, superClassName)) {
			NSCAssert(0, @"类 %@ 在ananas中与OC中父类名称不一致,ananas:%@ OC:%s ",classDefinition.name,classDefinition.superNmae, superClassName);
			return;
		}
	}
}


static ANCPropertyModifier currentModifier;


#define getter(_type,_value) \
static _type getter_##_type(id _self,SEL sel){\
	NSString *key = NSStringFromSelector(sel);\
	id value = objc_getAssociatedObject(_self,propKey(key));\
return _value;\
}
//static objc_AssociationPolicy policy;\
if (!_self) {\
	static dispatch_once_t onceToken;\
	dispatch_once(&onceToken, ^{\
		NSUInteger mem = currentModifier & ANCPropertyModifierMemMask;\
		NSUInteger atomic = currentModifier & ANCPropertyModifierAtomicMask;\
		if (mem == ANCPropertyModifierMemWeak) {\
			policy = OBJC_ASSOCIATION_ASSIGN;\
		}else if (mem == ANCPropertyModifierMemAssign){\
			policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;\
		}else if (mem == ANCPropertyModifierMemStrong && atomic == ANCPropertyModifierNonatomic) {\
			policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;\
		}else if (mem == ANCPropertyModifierMemCopy && atomic == ANCPropertyModifierNonatomic) {\
			policy = OBJC_ASSOCIATION_COPY_NONATOMIC;\
		}else if (mem == ANCPropertyModifierMemStrong && atomic == ANCPropertyModifierAtomic) {\
			policy = OBJC_ASSOCIATION_RETAIN;\
		}else if (mem == ANCPropertyModifierMemCopy && atomic == ANCPropertyModifierAtomic) {\
			policy = OBJC_ASSOCIATION_COPY;\
		}\
	});\
	return;\
}
#define setter(_type,_value,_policy)\
static void setter_##_type##_policy(id _self, SEL sel, _type value){\
	NSString *setter = NSStringFromSelector(sel);\
	NSString *firstString = [[setter substringWithRange:NSMakeRange(3, 1)] lowercaseString];\
	NSString *otherString = setter.length > 4 ? [setter substringFromIndex:4] : nil;\
	NSString *key = [NSString stringWithFormat:@"%@%@",firstString, otherString];\
	objc_setAssociatedObject(_self, propKey(key), _value, _policy);\
}

getter(BOOL, [value boolValue])
setter(BOOL,[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)

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
getter(longDouble, [value doubleValue])
setter(longDouble, [NSNumber numberWithDouble:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)

typedef const char * cstring;
getter(cstring, [value UTF8String])
setter(cstring, [NSString stringWithUTF8String:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC)

getter(Class, value)
setter(Class, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

getter(SEL, NSSelectorFromString(value))
setter(SEL, NSStringFromSelector(sel),OBJC_ASSOCIATION_RETAIN_NONATOMIC)

getter(id, value)
setter(id, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

getter(CGRect, [value CGRectValue])
setter(CGRect, [NSValue valueWithCGRect:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC)

getter(CGSize, [value CGSizeValue])

//CGRect CGSzie CGPointer CGAffineTransform NSRange



//ANC_TYPE_VOID,
//ANC_TYPE_BOOL,
//ANC_TYPE_NS_U_INTEGER,
//ANC_TYPE_NS_INTEGER,
//ANC_TYPE_CG_FLOAT,
//ANC_TYPE_DOUBLE,
//ANC_TYPE_STRING,//char *
//ANC_TYPE_CLASS,
//ANC_TYPE_SEL,
//ANC_TYPE_NS_OBJECT,
//ANC_TYPE_STRUCT,
//ANC_TYPE_NS_BLOCK,
//ANC_TYPE_ANANAS_BLOCK,
//ANC_TYPE_UNKNOWN

static void replace_getter_method(Class clazz, ANCPropertyDefinition *prop){
	switch (prop.typeSpecifier.typeKind) {
		case ANC_TYPE_BOOL:
			class_replaceMethod(clazz, NSSelectorFromString(prop.name), (IMP)getter_BOOL, "B@:");
			break;
			
		default:
			break;
	}
	
}


static void replace_setter_method(Class clazz, ANCPropertyDefinition *prop){

}

static void replace_getter_setter_method(Class clazz, ANCPropertyDefinition *prop){
	
}



static void replace_prop(ANCClassDefinition *classDefinition, ANCPropertyDefinition *prop){
	NSNumber *i;
	[i doubleValue];
	
	Class clazz = NSClassFromString(classDefinition.name);
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
//	NSString *varName = [NSString stringWithFormat:@"_%@",prop.name];
//	objc_property_attribute_t backingivar = {"V",varName.UTF8String};
	objc_property_attribute_t attrs[] = { type, memAttr, atomicAttr };
	class_replaceProperty(clazz, prop.name.UTF8String, attrs, 3);
	
	
}


static void fix_class(ANCInterpreter *interpreter,ANCClassDefinition *classDefinition){
	Class clazz = NSClassFromString(classDefinition.name);

	for (ANCPropertyDefinition *prop in classDefinition.properties) {

		
	
		
		
		
		
		
	
	}
	
	for (ANCMethodDefinition *classMethod in classDefinition.classMethods) {
		
	}
	
	for (ANCMethodDefinition *instanceMethod in classDefinition.instanceMethods) {
		
	}
	
	
	
}

void add_struct_declare(){
	
}









void anc_interpret(ANCInterpreter *interpreter){
	
	for (__kindof NSObject *top in interpreter.topList) {
		if ([top isKindOfClass:[ANCStatement class]]) {
			execute_statement();
		}else if ([top isKindOfClass:[ANCStructDeclare class]]){
			add_struct_declare();
		}else if ([top isKindOfClass:[ANCClassDefinition class]]){
			fix_class(interpreter,top);
		}
	}
	
	
}
