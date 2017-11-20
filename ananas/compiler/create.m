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

ANCExpression *anc_create_expression(ANCExpressionKind kind){
	Class clazz = anc_expression_class_of_kind(kind);
	ANCExpression *expr = [[clazz alloc] init];
	expr.expressionKind = kind;
	return expr;
}
//@property (strong, nonatomic) ANCTypeSpecifier *type;
//@property (copy, nonatomic) NSString *name;
//@property (strong, nonatomic) ANCExpression *initializer;
ANCDeclarationStatement *anc_create_declaration_statement(ANCTypeSpecifier *type, NSString *name, ANCExpression *initializer){
	ANCDeclaration *
	
}



ANCExpressionStatement *anc_create_expression_statement(ANCExpression *expr){
	ANCExpressionStatement *statement = [[ANCExpressionStatement alloc] init];
	statement.kind = ANCStatementKindExpression;
	statement.expr = expr;
	return statement;
}

ANCIfStatement *anc_create_if_statement(ANCExpression *condition,ANCBlock *thenBlock,ANCBlock *elseBlocl,NSArray<ANCElseIf *> *elseIfList){
	ANCIfStatement *statement = [[ANCIfStatement alloc] init];
	statement.kind = ANCStatementKindIf;
	statement.condition = condition;
	statement.thenBlock = thenBlock;
	statement.elseBlocl = elseBlocl;
	statement.elseIfList = elseIfList;
	return statement;
}


ANCSwitchStatement *anc_create_switch_statement(ANCExpression *expr, NSMutableArray<ANCCase *> *caseList, ANCBlock *defaultBlock){
	ANCSwitchStatement *statement = [[ANCSwitchStatement alloc] init];
	statement.kind = ANCStatementKindSwitch;
	statement.expr = expr;
	statement.caseList = caseList;
	statement.defaultBlock = defaultBlock;
	return statement;
}

ANCForStatement *anc_create_for_statement(NSString *label, ANCExpression *initializerExpr, ANCDeclaration *declaration,
										  ANCExpression *condition, ANCExpression *post, ANCBlock *block){
	ANCForStatement *statement = [[ANCForStatement alloc] init];
	statement.kind = ANCStatementKindFor;
	statement.label = label;
	statement.initializerExpr = initializerExpr;
	statement.declaration = declaration;
	statement.condition = condition;
	statement.post = post;
	statement.block = block;
	return statement;
}


ANCForEachStatement *anc_create_for_each_statement(NSString *label, ANCDeclaration *declaration, ANCExpression *varExpr, ANCExpression *arrayExpr,ANCBlock *block){
	ANCForEachStatement *statement = [[ANCForEachStatement alloc] init];
	statement.kind = ANCStatementKindForEach;
	statement.label  = label;
	statement.declaration = declaration;
	statement.varExpr = varExpr;
	statement.arrayExpr = arrayExpr;
	statement.block = block;
	return statement;
}


ANCWhileStatement *anc_create_while_statement(NSString *label, ANCExpression *condition, ANCBlock *block){
	ANCWhileStatement *statement = [[ANCWhileStatement alloc] init];
	statement.kind = ANCStatementKindWhile;
	statement.label = label;
	statement.condition = condition;
	statement.block = block;
	return statement;
}

ANCDoWhileStatement *anc_create_do_while_statement(NSString *label, ANCBlock *block, ANCExpression *condition){
	ANCDoWhileStatement *statement = [[ANCDoWhileStatement alloc] init];
	statement.kind = ANCStatementKindDoWhile;
	statement.label = label;
	statement.block = block;
	statement.condition = condition;
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

ANCTypeSpecifier *anc_create_block_type_specifier(ANCTypeSpecifier *returnTypeSpecifier,NSArray<ANCTypeSpecifier *> *paramsTypeSpecifier){
	ANCTypeSpecifier *typeSpecifier = [[ANCTypeSpecifier alloc] init];
	typeSpecifier.typeKind = ANC_TYPE_BLOCK;
	typeSpecifier.returnTypeSpecifier = returnTypeSpecifier;
	typeSpecifier.paramsTypeSpecifier = paramsTypeSpecifier;
	return typeSpecifier;
}

ANCFunctionDefinition *anc_create_function_definition(ANCTypeSpecifier *returnTypeSpecifier,NSString *name ,NSArray<ANCParameter *> *prasms){
	ANCFunctionDefinition *functionDefinition = [[ANCFunctionDefinition alloc] init];
	functionDefinition.returnTypeSpecifier = returnTypeSpecifier;
	functionDefinition.name = name;
	functionDefinition.params = prasms;
	return functionDefinition;
}

ANCMethodDefinition *anc_create_method_definition(BOOL classMethod, ANCFunctionDefinition *functionDefinition){
	ANCMethodDefinition *methodDefinition = [[ANCMethodDefinition alloc] init];
	methodDefinition.classMethod = classMethod;
	methodDefinition.functionDefinition = functionDefinition;
	return methodDefinition;
	
}

ANCPropertyDefinition *anc_create_property_definition(ANCPropertyModifier modifier, ANCTypeSpecifier *typeSpecifier, NSString *name){
	ANCPropertyDefinition *propertyDefinition = [[ANCPropertyDefinition alloc] init];
	propertyDefinition.modifier = modifier;
	propertyDefinition.typeSpecifier = typeSpecifier;
	propertyDefinition.name = name;
	return propertyDefinition;
}

ANCClassDefinition *anc_create_class_definition(NSString *name, NSString *superNmae, NSArray<NSString *> *protocolNames,
												NSArray<ANCMemberDefinition *> *members){
	ANCClassDefinition *classDefinition = [[ANCClassDefinition alloc] init];
	classDefinition.name = name;
	classDefinition.superNmae = superNmae;
	classDefinition.protocolNames = protocolNames;
	NSMutableArray<ANCPropertyDefinition *> *propertyDefinition = [NSMutableArray array];
	NSMutableArray<ANCMethodDefinition *> *classMethods = [NSMutableArray array];
	NSMutableArray<ANCMethodDefinition *> *instanceMethods = [NSMutableArray array];
	for (ANCMemberDefinition *memberDefinition in members) {
		if ([memberDefinition isKindOfClass:[ANCPropertyDefinition class]]) {
			[propertyDefinition addObject:(ANCPropertyDefinition *)memberDefinition];
		}else if ([memberDefinition isKindOfClass:[ANCMethodDefinition class]]){
			ANCMethodDefinition *methodDefinition = (ANCMethodDefinition *)memberDefinition;
			if (methodDefinition.classMethod) {
				[classMethods addObject:methodDefinition];
			}else{
				[instanceMethods addObject:methodDefinition];
			}
		}
	}
	classDefinition.properties = propertyDefinition;
	classDefinition.classMethods = classMethods;
	classDefinition.instanceMethods = instanceMethods;
	return classDefinition;
	
}














