//
//  ANCValue.m
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANEValue.h"

@implementation ANEValue
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
- (BOOL)isTrue{
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

@end
