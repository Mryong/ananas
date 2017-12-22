//
//  util.c
//  ananasExample
//
//  Created by jerry.yong on 2017/11/28.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "anc_ast.h"


ANCTypeSpecifier *anc_alloc_type_specifier(ANCTypeSpecifierKind kind, NSString *identifier, NSString *typeEncoding){
	ANCTypeSpecifier *typeSpecifier = [[ANCTypeSpecifier alloc] init];
	typeSpecifier.typeKind = kind;
	
	if (identifier) {
		typeSpecifier.typeEncoding = typeEncoding;
	}else{
		switch (kind) {
			case ANC_TYPE_VOID:
				typeSpecifier.typeEncoding = @"v";
				break;
			case ANC_TYPE_BOOL:
				typeSpecifier.typeEncoding = @"B";
				break;
			case ANC_TYPE_NS_U_INTEGER:
				typeSpecifier.typeEncoding = @"Q";
				break;
			case ANC_TYPE_NS_INTEGER:
				typeSpecifier.typeEncoding = @"q";
				break;
			case ANC_TYPE_CG_FLOAT:
				typeSpecifier.typeEncoding = @"D";
				break;
			case ANC_TYPE_DOUBLE:
				typeSpecifier.typeEncoding = @"d";
				break;
			case ANC_TYPE_STRING:
				typeSpecifier.typeEncoding = @"*";
				break;
			case ANC_TYPE_CLASS:
				typeSpecifier.typeEncoding = @"#";
				break;
			case ANC_TYPE_SEL:
				typeSpecifier.typeEncoding = @":";
				break;
			case ANC_TYPE_OC:
				typeSpecifier.typeEncoding = @"@";
				break;
			case ANC_TYPE_BLOCK:
				typeSpecifier.typeEncoding = @"?@";
				break;
			case ANC_TYPE_STRUCT:
				typeSpecifier.typeEncoding = @"";
				break;
			case ANC_TYPE_UNKNOWN:
				typeSpecifier.typeEncoding = @"?";
				break;
				
			default:
				NSCAssert(0, @"kind = %ld", kind);
				break;
		}
	}
	
	if (identifier) {
		typeSpecifier.identifer = identifier;
	}
	
	
	return typeSpecifier;
	
}
