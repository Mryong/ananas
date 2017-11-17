//
//  create.c
//  ananasExample
//
//  Created by Superdan on 2017/11/1.
//  Copyright © 2017年 xiaodongdan. All rights reserved.
//

#include <stdio.h>
#include "ananasc.h"
#import "ANCExpression.h"
#import "ANCStatement.h"
#import "ANCStructDeclare.h"

int line_number = 1;

#define STRING_ALLOC_SIZE (256)
static char *st_string_literal_buffer = NULL;
static int st_string_literal_buffer_size = 0;
static int st_string_literal_buffer_alloc_size = 0;



int yyerror(char const *str){
	printf("line:%d: %s\n",line_number,str);
	return 0;
}


NSString *anc_create_identifier(char *str){
	NSString *ocStr = [NSString stringWithUTF8String:str];
	return ocStr;
}




void anc_open_string_literal_buf(){
	st_string_literal_buffer_size = 0;
}

void anc_append_string_literal(int letter){
	if (st_string_literal_buffer_size >= st_string_literal_buffer_alloc_size) {
		st_string_literal_buffer_alloc_size +=  STRING_ALLOC_SIZE;
		void *new_pointer = realloc(st_string_literal_buffer, st_string_literal_buffer_alloc_size);
		free(st_string_literal_buffer);
		st_string_literal_buffer = new_pointer;
	}
	
	st_string_literal_buffer[st_string_literal_buffer_size] = letter;
	st_string_literal_buffer_size++;
}

void anc_rest_string_literal_buffer(void){
	free(st_string_literal_buffer);
	st_string_literal_buffer = NULL;
	st_string_literal_buffer_size = 0;
	st_string_literal_buffer_alloc_size = 0;
	
}

NSMutableString *anc_end_string_literal(){
	anc_append_string_literal('\0');
	NSMutableString *str = [NSMutableString stringWithUTF8String:st_string_literal_buffer];
	anc_rest_string_literal_buffer();
	return str;
}

Class anc_expression_class_of_kind(ANCExpressionKind kind){
	switch (kind) {
		case ANC_BOOLEAN_EXPRESSION:
		case ANC_INT_EXPRESSION:
		case ANC_U_INT_EXPRESSION:
		case ANC_FLOAT_EXPRESSION:
		case ANC_DOUBLE_EXPRESSION:
		case ANC_STRING_EXPRESSION:
		case ANC_SELF_EXPRESSION:
		case ANC_SUPER_EXPRESSION:
		case ANC_NIL_EXPRESSION:
			return [ANCExpression class];
		case ANC_IDENTIFIER_EXPRESSION:
			return [ANCIdentifierExpression class];
		case ANC_ASSIGN_EXPRESSION:
			return [ANCAssignExpression class];
		case ANC_PLUS_EXPRESSION:
		case ANC_MINUS_EXPRESSION:
		case ANC_MUL_EXPRESSION:
		case ANC_DIV_EXPRESSION:
		case ANC_MOD_EXPRESSION:
		case ANC_EQ_EXPRESSION:
		case ANC_NE_EXPRESSION:
		case ANC_GT_EXPRESSION:
		case ANC_GE_EXPRESSION:
		case ANC_LT_EXPRESSION:
		case ANC_LE_EXPRESSION:
		case ANC_LOGICAL_AND_EXPRESSION:
		case ANC_LOGICAL_OR_EXPRESSION:
			return [ANCBinaryExpression class];
		case ANC_LOGICAL_NOT_EXPRESSION:
		case ANC_INCREMENT_EXPRESSION:
		case ANC_DECREMENT_EXPRESSION:
		case NSC_NEGATIVE_EXPRESSION:
			return [ANCUnaryExpression class];
		case ANC_INDEX_EXPRESSION:
			return [ANCIndexExpression class];
		case ANC_MEMBER_EXPRESSION:
			return [ANCMemberExpression class];
		case ANC_FUNCTION_CALL_EXPRESSION:
			return [ANCFunctonCallExpression class];
		case ANC_DIC_LITERAL_EXPRESSION:
			return [ANCDictionaryExpression class];
		case ANC_STRUCT_LITERAL_EXPRESSION:
			return [ANCStructpression class];
		case ANC_ARRAY_LITERAL_EXPRESSION:
			return [ANCArrayExpression class];
		default:
			return [ANCExpression class];
	}
	
}

ANCExpression* anc_create_expression(ANCExpressionKind kind){
	Class clazz = anc_expression_class_of_kind(kind);
	ANCExpression *expr = [[clazz alloc] init];
	expr.expressionKind = kind;
	return expr;
}

Class anc_statement_class_of_kind(ANCStatementKind kind){
	switch (kind) {
		case ANCStatementKindExpression:
			return [ANCExpressionStatement class];
		case ANCStatementKindDeclaration:
			return [ANCDeclarationStatement class];
		case ANCStatementKindIf:
			return [ANCIfStatement class];
		case ANCStatementKindSwitch:
			return [ANCSwitchStatement class];
		case ANCStatementKindFor:
			return [ANCForStatement class];
		case ANCStatementKindForEach:
			return [ANCForEachStatement class];
		case ANCStatementKindWhile:
			return [ANCWhileStatement class];
		case ANCStatementKindDoWhile:
			return [ANCDoWhileStatement class];
		case ANCStatementKindContinue:
			return [ANCContinueStatement class];
		case ANCStatementKindBreak:
			return [ANCContinueStatement class];
		case ANCStatementKindReturn:
			return [ANCReturnStatement class];
		default:
			return [ANCStatement class];
	}
	
}

ANCStatement *anc_create_statement(ANCStatementKind kind){
	Class clazz = anc_statement_class_of_kind(kind);
	ANCStatement *statement = [[clazz alloc] init];
	statement.kind = kind;
	return statement;
}


ANCStructDeclare *anc_create_struct_declare(NSString *structName, NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue){
	if (![typeEncodingKey isEqualToString:@"typeEncoding"]) {
	
	}
	
	if (![keysKey isEqualToString:@"keys"]) {
		
	}
	
	ANCStructDeclare *structDeclare = [[ANCStructDeclare alloc] init];
	structDeclare.typeEncoding = typeEncodingValue;
	structDeclare.keys = keysValue;
	
	return structDeclare;
	
}

ANCTypeSpecifier *anc_create_type_specifier(ANCExpressionTypeKind kind, NSString *identifier, NSString *typeEncoding){
	ANCTypeSpecifier *typeSpecifier = [[ANCTypeSpecifier alloc] init];
	typeSpecifier.typeKind = kind;
	typeSpecifier.identifer = identifier;
	typeSpecifier.typeEncoding = typeEncoding;
	return typeSpecifier;
	
}










