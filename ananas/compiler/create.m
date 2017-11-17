//
//  create.c
//  ananasExample
//
//  Created by Superdan on 2017/11/1.
//  Copyright © 2017年 xiaodongdan. All rights reserved.
//

#include <stdio.h>
#include "ananasc.h"
#import "NACExpression.h"
#import "NACStatement.h"
#import "NACStructDeclare.h"

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

void nac_rest_string_literal_buffer(void){
	free(st_string_literal_buffer);
	st_string_literal_buffer = NULL;
	st_string_literal_buffer_size = 0;
	st_string_literal_buffer_alloc_size = 0;
	
}

NSMutableString *anc_end_string_literal(){
	anc_append_string_literal('\0');
	NSMutableString *str = [NSMutableString stringWithUTF8String:st_string_literal_buffer];
	nac_rest_string_literal_buffer();
	return str;
}

Class anc_expression_class_of_kind(NACExpressionKind kind){
	switch (kind) {
		case NAC_BOOLEAN_EXPRESSION:
		case NAC_INT_EXPRESSION:
		case NAC_U_INT_EXPRESSION:
		case NAC_FLOAT_EXPRESSION:
		case NAC_DOUBLE_EXPRESSION:
		case NAC_STRING_EXPRESSION:
		case NAC_SELF_EXPRESSION:
		case NAC_SUPER_EXPRESSION:
		case NAC_NIL_EXPRESSION:
			return [NACExpression class];
		case NAC_IDENTIFIER_EXPRESSION:
			return [NACIdentifierExpression class];
		case NAC_ASSIGN_EXPRESSION:
			return [NACAssignExpression class];
		case NAC_PLUS_EXPRESSION:
		case NAC_MINUS_EXPRESSION:
		case NAC_MUL_EXPRESSION:
		case NAC_DIV_EXPRESSION:
		case NAC_MOD_EXPRESSION:
		case NAC_EQ_EXPRESSION:
		case NAC_NE_EXPRESSION:
		case NAC_GT_EXPRESSION:
		case NAC_GE_EXPRESSION:
		case NAC_LT_EXPRESSION:
		case NAC_LE_EXPRESSION:
		case NAC_LOGICAL_AND_EXPRESSION:
		case NAC_LOGICAL_OR_EXPRESSION:
			return [NACBinaryExpression class];
		case NAC_LOGICAL_NOT_EXPRESSION:
		case NAC_INCREMENT_EXPRESSION:
		case NAC_DECREMENT_EXPRESSION:
		case NSC_NEGATIVE_EXPRESSION:
			return [NACUnaryExpression class];
		case NAC_INDEX_EXPRESSION:
			return [NACIndexExpression class];
		case NAC_MEMBER_EXPRESSION:
			return [NACMemberExpression class];
		case NAC_FUNCTION_CALL_EXPRESSION:
			return [NACFunctonCallExpression class];
		case NAC_DIC_LITERAL_EXPRESSION:
			return [NACDictionaryExpression class];
		case NAC_STRUCT_LITERAL_EXPRESSION:
			return [NACStructpression class];
		case NAC_ARRAY_LITERAL_EXPRESSION:
			return [NACArrayExpression class];
		default:
			return [NACExpression class];
	}
	
}

NACExpression* anc_create_expression(NACExpressionKind kind){
	Class clazz = anc_expression_class_of_kind(kind);
	NACExpression *expr = [[clazz alloc] init];
	expr.expressionKind = kind;
	return expr;
}

Class anc_statement_class_of_kind(NACStatementKind kind){
	switch (kind) {
		case NACStatementKindExpression:
			return [NACExpressionStatement class];
		case NACStatementKindDeclaration:
			return [NACDeclarationStatement class];
		case NACStatementKindIf:
			return [NACIfStatement class];
		case NACStatementKindSwitch:
			return [NACSwitchStatement class];
		case NACStatementKindFor:
			return [NACForStatement class];
		case NACStatementKindForEach:
			return [NACForEachStatement class];
		case NACStatementKindWhile:
			return [NACWhileStatement class];
		case NACStatementKindDoWhile:
			return [NACDoWhileStatement class];
		case NACStatementKindContinue:
			return [NACContinueStatement class];
		case NACStatementKindBreak:
			return [NACContinueStatement class];
		case NACStatementKindReturn:
			return [NACReturnStatement class];
		default:
			return [NACStatement class];
	}
	
}

NACStatement *anc_create_statement(NACStatementKind kind){
	Class clazz = anc_statement_class_of_kind(kind);
	NACStatement *statement = [[clazz alloc] init];
	statement.kind = kind;
	return statement;
}


NACStructDeclare *nac_create_struct_declare(NSString *structName, NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue){
	if (![typeEncodingKey isEqualToString:@"typeEncoding"]) {
		NACFunctonCallExpression *expr = (NACFunctonCallExpression *)anc_create_expression(NAC_FUNCTION_CALL_EXPRESSION);
		expr.expr;
		expr.args;
		
	}
	
	if (![keysKey isEqualToString:@"keys"]) {
		
	}
	
	NACStructDeclare *structDeclare = [[NACStructDeclare alloc] init];
	structDeclare.typeEncoding = typeEncodingValue;
	structDeclare.keys = keysValue;
	
	return structDeclare;
	
}










