//
//  create.c
//  ananasExample
//
//  Created by Superdan on 2017/11/1.
//  Copyright © 2017年 xiaodongdan. All rights reserved.
//

#include <stdio.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include "ananasc.h"


static ANCInterpreter *st_current_compile_util;







#define STRING_ALLOC_SIZE (256)
static char *st_string_literal_buffer = NULL;
static int st_string_literal_buffer_size = 0;
static int st_string_literal_buffer_alloc_size = 0;



int yyerror(char const *str){
	printf("line:%zd: %s\n",anc_get_current_compile_util().currentLineNumber,str);
	return 0;
}


ANCInterpreter *anc_get_current_compile_util(){
	return st_current_compile_util;
}

void anc_set_current_compile_util(ANCInterpreter *interpreter){
	st_current_compile_util = interpreter;
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

const char *anc_end_string_literal(){
	anc_append_string_literal('\0');
	size_t strLen = strlen(st_string_literal_buffer);
	char *str = malloc(strLen + 1);
	strcpy(str, st_string_literal_buffer);
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
		case ANC_SELECTOR_EXPRESSION:
		case ANC_SUPER_EXPRESSION:
		case ANC_NIL_EXPRESSION:
			return [ANCExpression class];
		case ANC_IDENTIFIER_EXPRESSION:
			return [ANCIdentifierExpression class];
		case ANC_BLOCK_EXPRESSION:
			return [ANCBlockExpression class];
		case ANC_ASSIGN_EXPRESSION:
			return [ANCAssignExpression class];
		case ANC_TERNARY_EXPRESSION:
			return [ANCTernaryExpression class];
		case ANC_ADD_EXPRESSION:
		case ANC_SUB_EXPRESSION:
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
		case ANC_AT_EXPRESSION:
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

ANCDicEntry *anc_create_dic_entry(ANCExpression *keyExpr, ANCExpression *valueExpr){
	ANCDicEntry *dicEntry = [[ANCDicEntry alloc] init];
	dicEntry.keyExpr = keyExpr;
	dicEntry.valueExpr = valueExpr;
	return dicEntry;
}

ANCExpression *anc_create_expression(ANCExpressionKind kind){
	Class clazz = anc_expression_class_of_kind(kind);
	ANCExpression *expr = [[clazz alloc] init];
	expr.expressionKind = kind;
	return expr;
}


void anc_build_block_expr(ANCBlockExpression *expr, ANCTypeSpecifier *returnTypeSpecifier, NSArray<ANCParameter *> *params, ANCBlock *block){
	ANCFunctionDefinition *func = [[ANCFunctionDefinition alloc] init];
	func.kind = ANCFunctionDefinitionKindBlock;
	if (!returnTypeSpecifier) {
		returnTypeSpecifier = anc_create_type_specifier(ANC_TYPE_VOID);
	}
	func.returnTypeSpecifier = returnTypeSpecifier;
	func.params  = params;
	func.block = block;
	expr.func = func;
	
}



ANCDeclaration *anc_create_declaration(ANCTypeSpecifier *type, NSString *name, ANCExpression *initializer){
	ANCDeclaration *declaration = [[ANCDeclaration alloc] init];
	declaration.type = type;
	declaration.name = name;
	declaration.initializer = initializer;
	return declaration;
}

ANCDeclarationStatement *anc_create_declaration_statement(ANCDeclaration *declaration){
	ANCDeclarationStatement *statement = [[ANCDeclarationStatement alloc] init];
	statement.kind = ANCStatementKindDeclaration;
	statement.declaration = declaration;
	return statement;
	
}



ANCExpressionStatement *anc_create_expression_statement(ANCExpression *expr){
	ANCExpressionStatement *statement = [[ANCExpressionStatement alloc] init];
	statement.kind = ANCStatementKindExpression;
	statement.expr = expr;
	return statement;
}

ANCElseIf *anc_create_else_if(ANCExpression *condition, ANCBlock *thenBlock){
	ANCElseIf *elseIf = [[ANCElseIf alloc] init];
	elseIf.condition = condition;
	elseIf.thenBlock = thenBlock;
	return elseIf;
}


ANCIfStatement *anc_create_if_statement(ANCExpression *condition,ANCBlock *thenBlock,NSArray<ANCElseIf *> *elseIfList,ANCBlock *elseBlocl){
	ANCIfStatement *statement = [[ANCIfStatement alloc] init];

	
	statement.kind = ANCStatementKindIf;
	statement.condition = condition;
	statement.thenBlock = thenBlock;
	statement.elseBlocl = elseBlocl;
	statement.elseIfList = elseIfList;
	return statement;
}



ANCCase *anc_create_case(ANCExpression *expr, ANCBlock *block){
	ANCCase *case_ = [[ANCCase alloc] init];
	case_.expr = expr;
	case_.block = block;
	return case_;
}

ANCSwitchStatement *anc_create_switch_statement(ANCExpression *expr, NSArray<ANCCase *> *caseList, ANCBlock *defaultBlock){
	ANCSwitchStatement *statement = [[ANCSwitchStatement alloc] init];
	
	statement.kind = ANCStatementKindSwitch;
	statement.expr = expr;
	statement.caseList = caseList;
	statement.defaultBlock = defaultBlock;
	return statement;
}


ANCForStatement *anc_create_for_statement(ANCExpression *initializerExpr, ANCDeclaration *declaration,
										  ANCExpression *condition, ANCExpression *post, ANCBlock *block){
	ANCForStatement *statement = [[ANCForStatement alloc] init];
	
	statement.kind = ANCStatementKindFor;
	statement.initializerExpr = initializerExpr;
	statement.declaration = declaration;
	statement.condition = condition;
	statement.post = post;
	statement.block = block;
	return statement;
}


ANCForEachStatement *anc_create_for_each_statement(ANCTypeSpecifier *typeSpecifier,NSString *varName, ANCExpression *arrayExpr,ANCBlock *block){
	ANCForEachStatement *statement = [[ANCForEachStatement alloc] init];
	
	
	statement.kind = ANCStatementKindForEach;
	if (typeSpecifier) {
		statement.declaration = anc_create_declaration(typeSpecifier, varName, nil);
	}else{
		ANCIdentifierExpression *varExpr = (ANCIdentifierExpression *)anc_create_expression(ANC_IDENTIFIER_EXPRESSION);
		varExpr.identifier = varName;
		statement.identifierExpr = varExpr;
	}
	
	statement.arrayExpr = arrayExpr;
	statement.block = block;
	return statement;
}


ANCWhileStatement *anc_create_while_statement(ANCExpression *condition, ANCBlock *block){
	ANCWhileStatement *statement = [[ANCWhileStatement alloc] init];
	statement.kind = ANCStatementKindWhile;
	statement.condition = condition;
	statement.block = block;
	return statement;
}

ANCDoWhileStatement *anc_create_do_while_statement(ANCBlock *block, ANCExpression *condition){
	ANCDoWhileStatement *statement = [[ANCDoWhileStatement alloc] init];
	statement.kind = ANCStatementKindDoWhile;
	statement.block = block;
	statement.condition = condition;
	return statement;
}

ANCContinueStatement *anc_create_continue_statement(){
	ANCContinueStatement *statement = [[ANCContinueStatement alloc] init];
	statement.kind = ANCStatementKindContinue;
	return statement;
}


ANCBreakStatement *anc_create_break_statement(){
	ANCBreakStatement *statement = [[ANCBreakStatement alloc] init];
	statement.kind = ANCStatementKindBreak;
	return statement;
	
}

ANCReturnStatement *anc_create_return_statement(ANCExpression *retValExpr){
	ANCReturnStatement *statement = [[ANCReturnStatement alloc] init];
	statement.kind = ANCStatementKindReturn;
	statement.retValExpr = retValExpr;
	return statement;
}



ANCBlock *anc_open_block_statement(){
	ANCBlock *block = [[ANCBlock alloc] init];
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	block.outBlock = interpreter.currentBlock;
	interpreter.currentBlock = block;
	return block;
	
}

ANCBlock *anc_close_block_statement(ANCBlock *block, NSArray<ANCStatement *> *statementList){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	NSCAssert(block == interpreter.currentBlock, @"block != anc_get_current_compile_util().currentBlock");
	interpreter.currentBlock = block.outBlock;
	block.statementList = statementList;
	return block;
}









ANCStructDeclare *anc_create_struct_declare(ANCExpression *annotaionIfConditionExpr, NSString *structName, NSString *typeEncodingKey, const char *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue){
	if (![typeEncodingKey isEqualToString:@"typeEncoding"]) {
		anc_compile_err(0, ANCCompileErrorStructDeclareLackTypeEncoding);
	}
	
	if (![keysKey isEqualToString:@"keys"]) {
		anc_compile_err(0, ANCCompileErrorStructDeclareLackTypeKeys);
	}
	
	ANCStructDeclare *structDeclare = [[ANCStructDeclare alloc] init];
	structDeclare.annotationIfConditionExpr = annotaionIfConditionExpr;
	structDeclare.lineNumber = 0;
	structDeclare.name = structName;
	structDeclare.typeEncoding = typeEncodingValue;
	structDeclare.keys = keysValue;
	
	return structDeclare;
	
}

ANCTypeSpecifier *anc_create_type_specifier(ANATypeSpecifierKind kind){
	ANCTypeSpecifier *typeSpecifier = [[ANCTypeSpecifier alloc] init];
	typeSpecifier.typeKind = kind;
	return typeSpecifier;
}

ANCTypeSpecifier *anc_create_struct_type_specifier(NSString *structName){
	ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT);
	typeSpecifier.structName = structName;
	return typeSpecifier;
}


ANCParameter *anc_create_parameter(ANCTypeSpecifier *type, NSString *name){
	ANCParameter *parameter = [[ANCParameter alloc] init];
	parameter.type = type;
	parameter.name = name;
	parameter.lineNumber = anc_get_current_compile_util().currentLineNumber;
	return parameter;
}

ANCFunctionDefinition *anc_create_function_definition(ANCTypeSpecifier *returnTypeSpecifier,NSString *name ,NSArray<ANCParameter *> *prasms,
													  ANCBlock *block){
	ANCFunctionDefinition *functionDefinition = [[ANCFunctionDefinition alloc] init];
	functionDefinition.returnTypeSpecifier = returnTypeSpecifier;
	functionDefinition.name = name;
	functionDefinition.params = prasms;
	functionDefinition.block = block;
	return functionDefinition;
}

ANCMethodNameItem *anc_create_method_name_item(NSString *name, ANCTypeSpecifier *typeSpecifier, NSString *paramName){
	ANCMethodNameItem *item = [[ANCMethodNameItem alloc] init];
	item.name = name;
	if (typeSpecifier && paramName) {
		ANCParameter *param = [[ANCParameter alloc] init];
		param.type = typeSpecifier;
		param.name = paramName;
		item.param = param;
	}
	
	
	return item;
	
}

ANCMethodDefinition *anc_create_method_definition(ANCExpression *annotaionIfConditionExpr, BOOL classMethod, ANCTypeSpecifier *returnTypeSpecifier, NSArray<ANCMethodNameItem *> *items, ANCBlock *block){
	ANCMethodDefinition *methodDefinition = [[ANCMethodDefinition alloc] init];
	methodDefinition.annotationIfConditionExpr = annotaionIfConditionExpr;
	methodDefinition.classMethod = classMethod;
	ANCFunctionDefinition *funcDefinition = [[ANCFunctionDefinition alloc] init];
	funcDefinition.kind = ANCFunctionDefinitionKindMethod;
	funcDefinition.returnTypeSpecifier = returnTypeSpecifier;
	NSMutableArray<ANCParameter *> *params = [NSMutableArray array];
	ANCParameter *selfParam = [[ANCParameter alloc] init];
	selfParam.type = anc_create_type_specifier(ANC_TYPE_OBJECT);
	selfParam.name = @"self";
	
	ANCParameter *selParam = [[ANCParameter alloc] init];
	selParam.type = anc_create_type_specifier(ANC_TYPE_SEL);
	selParam.name = @"_cmd";
	
	[params addObject:selfParam];
	[params addObject:selParam];
	
	NSMutableString *selector = [NSMutableString string];
	for (ANCMethodNameItem *itme in items) {
		[selector appendString:itme.name];
		if (itme.param) {
			[params addObject:itme.param];
		}
		
	}
	funcDefinition.name = selector;
	funcDefinition.params = params;
	funcDefinition.block = block;
	methodDefinition.functionDefinition = funcDefinition;
	return methodDefinition;
	
}

ANCPropertyDefinition *anc_create_property_definition(ANCExpression *annotaionIfConditionExpr, ANCPropertyModifier modifier, ANCTypeSpecifier *typeSpecifier, NSString *name){
	ANCPropertyDefinition *propertyDefinition = [[ANCPropertyDefinition alloc] init];
	propertyDefinition.annotationIfConditionExpr = annotaionIfConditionExpr;
	propertyDefinition.lineNumber = anc_get_current_compile_util().currentLineNumber;
	propertyDefinition.modifier = modifier;
	propertyDefinition.typeSpecifier = typeSpecifier;
	propertyDefinition.name = name;
	return propertyDefinition;
}

void anc_start_class_definition(ANCExpression *annotaionIfConditionExpr, NSString *name, NSString *superNmae, NSArray<NSString *> *protocolNames){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	ANCClassDefinition *classDefinition = [[ANCClassDefinition alloc] init];
	classDefinition.lineNumber = interpreter.currentLineNumber;
	classDefinition.annotationIfConditionExpr = annotaionIfConditionExpr;
	classDefinition.name = name;
	classDefinition.superNmae = superNmae;
	classDefinition.protocolNames = protocolNames;
	interpreter.currentClassDefinition = classDefinition;
}


ANCClassDefinition *anc_end_class_definition(NSArray<ANCMemberDefinition *> *members){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	ANCClassDefinition *classDefinition = interpreter.currentClassDefinition;
	NSMutableArray<ANCPropertyDefinition *> *propertyDefinition = [NSMutableArray array];
	NSMutableArray<ANCMethodDefinition *> *classMethods = [NSMutableArray array];
	NSMutableArray<ANCMethodDefinition *> *instanceMethods = [NSMutableArray array];
	for (ANCMemberDefinition *memberDefinition in members) {
		memberDefinition.classDefinition = classDefinition;
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
	interpreter.currentClassDefinition = nil;
	return classDefinition;
}

void anc_add_struct_declare(ANCStructDeclare *structDeclare){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	interpreter.structDeclareDic[structDeclare.name] = structDeclare;
	[interpreter.topList addObject:structDeclare];
}

void anc_add_class_definition(ANCClassDefinition *classDefinition){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	interpreter.classDefinitionDic[classDefinition.name] = classDefinition;
	[interpreter.topList addObject:classDefinition];
	
}

void anc_add_statement(ANCStatement *statement){
	ANCInterpreter *interpreter = anc_get_current_compile_util();
	[interpreter.topList addObject:statement];

}




void ane_test(id obj){
	NSLog(@"%@",obj);
}













