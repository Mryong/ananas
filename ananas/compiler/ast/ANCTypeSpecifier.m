//
//  NSCTypeSpecifier.m
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCTypeSpecifier.h"
#import "ANCInterpreter.h"
#import "ANANASStructDeclareTable.h"


@implementation ANCTypeSpecifier
- (const char *)typeEncoding{
	if (self.typeKind == ANC_TYPE_STRUCT || self.typeKind == ANC_TYPE_STRUCT_LITERAL) {
		ANANASStructDeclareTable *table = [ANANASStructDeclareTable shareInstance];
		return [table getStructDeclareWithName:self.structName].typeEncoding;
	}
	static NSDictionary *_dic;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dic = @{
				  @(ANC_TYPE_VOID):@"v",
				  @(ANC_TYPE_BOOL):@"B",
				  @(ANC_TYPE_INT):@"q",
				  @(ANC_TYPE_U_INT):@"Q",
				  @(ANC_TYPE_DOUBLE):@"d",
				  @(ANC_TYPE_C_STRING):@"*",
				  @(ANC_TYPE_POINTER):@"^v",
				  @(ANC_TYPE_CLASS):@"#",
				  @(ANC_TYPE_SEL):@":",
				  @(ANC_TYPE_OBJECT):@"@",
				  @(ANC_TYPE_BLOCK):@"@?"
				 };
	});
	return [_dic[@(self.typeKind)] UTF8String];
}

- (NSString *)typeName{
	if (self.typeKind == ANC_TYPE_STRUCT || self.typeKind == ANC_TYPE_STRUCT_LITERAL) {
		return _structName;
	}
	static NSDictionary *_dic;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dic = @{
				 @(ANC_TYPE_VOID):@"void",
				 @(ANC_TYPE_BOOL):@"BOOL",
				 @(ANC_TYPE_INT):@"int(long long int)",
				 @(ANC_TYPE_U_INT):@"uint(unsigned long long int)",
				 @(ANC_TYPE_DOUBLE):@"double",
				 @(ANC_TYPE_C_STRING):@"cstring(char *)",
				 @(ANC_TYPE_POINTER):@"pointer(char *)",
				 @(ANC_TYPE_CLASS):@"Class",
				 @(ANC_TYPE_SEL):@"SEL",
				 @(ANC_TYPE_OBJECT):@"id",
				 @(ANC_TYPE_BLOCK):@"NSBlock"
				 };
	});
	return _dic[@(self.typeKind)];
}







@end
