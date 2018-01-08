//
//  ananasc.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/1.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#ifndef ananasc_h
#define ananasc_h
#import "anc_ast.h"
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>


#define smaller(a, b) ((a) < (b) ? (a) : (b))
#define larger(a, b) ((a) > (b) ? (a) : (b))

typedef NS_ENUM(NSUInteger, ANCCompileError) {
	ANCCompileErrorStructDeclareRedefinition,
	ANCCompileErrorStructDeclareLackTypeEncoding,
	ANCCompileErrorStructDeclareLackTypeKeys,
	ANCSameClassDefinitionDifferentSuperClass,
	ANCRedefinitionPropertyInSameClass,
	ANCRedefinitionPropertyInChildClass,
	ANCParameterRedefinition,
	
	
};


/* errorc.c */
void anc_compile_err(NSUInteger lineNumber,ANCCompileError error,...);


/* util.c */
ANCTypeSpecifier *anc_alloc_type_specifier(ANCTypeSpecifierKind kind, NSString *identifier, NSString *typeEncoding);


/* create.m */
void anc_open_string_literal_buf(void);
void anc_append_string_literal(int letter);
const char* anc_end_string_literal(void);
NSString *anc_create_identifier(char *str);
ANCDicEntry *anc_create_dic_entry(ANCExpression *keyExpr, ANCExpression *valueExpr);
ANCExpression *anc_create_expression(ANCExpressionKind kind);
void anc_build_block_expr(ANCBlockExpression *expr, ANCTypeSpecifier *returnTypeSpecifier, NSArray<ANCParameter *> *params, ANCBlock *block);
ANCStructDeclare *anc_create_struct_declare(ANCExpression *annotaionIfConditionExpr, NSString *structName, NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue);
ANCTypeSpecifier *anc_create_type_specifier(ANCTypeSpecifierKind kind, NSString *identifier, NSString *typeEncoding);
ANCTypeSpecifier *anc_create_block_type_specifier(ANCTypeSpecifier *returnTypeSpecifier,NSArray<ANCTypeSpecifier *> *paramsTypeSpecifier);
ANCParameter *anc_create_parameter(ANCTypeSpecifier *type, NSString *name);
ANCDeclaration *anc_create_declaration(ANCTypeSpecifier *type, NSString *name, ANCExpression *initializer);
ANCDeclarationStatement *anc_create_declaration_statement(ANCDeclaration *declaration);
ANCExpressionStatement *anc_create_expression_statement(ANCExpression *expr);
ANCElseIf *anc_create_else_if(ANCExpression *condition, ANCBlock *thenBlock);
ANCIfStatement *anc_create_if_statement(ANCExpression *condition,ANCBlock *thenBlock,NSArray<ANCElseIf *> *elseIfList,ANCBlock *elseBlocl);
ANCCase *anc_create_case(ANCExpression *expr, ANCBlock *block);
ANCSwitchStatement *anc_create_switch_statement(ANCExpression *expr, NSArray<ANCCase *> *caseList, ANCBlock *defaultBlock);
ANCForStatement *anc_create_for_statement(ANCExpression *initializerExpr, ANCDeclaration *declaration,
										  ANCExpression *condition, ANCExpression *post, ANCBlock *block);
ANCForEachStatement *anc_create_for_each_statement( ANCTypeSpecifier *typeSpecifier, NSString *varName, ANCExpression *arrayExpr, ANCBlock *block);
ANCWhileStatement *anc_create_while_statement(ANCExpression *condition, ANCBlock *block);
ANCDoWhileStatement *anc_create_do_while_statement( ANCBlock *block, ANCExpression *condition);
ANCContinueStatement *anc_create_continue_statement(void);
ANCBreakStatement *anc_create_break_statement(void);
ANCReturnStatement *anc_create_return_statement(ANCExpression *retValExpr);
ANCBlock *anc_open_block_statement(void);
ANCBlock *anc_close_block_statement(ANCBlock *block, NSArray<ANCStatement *> *statementList);
void anc_start_class_definition(ANCExpression *annotaionIfConditionExpr, NSString *name, NSString *superNmae, NSArray<NSString *> *protocolNames);
ANCClassDefinition *anc_end_class_definition(NSArray<ANCMemberDefinition *> *members);

ANCFunctionDefinition *anc_create_function_definition(ANCTypeSpecifier *returnTypeSpecifier,NSString *name ,NSArray<ANCParameter *> *prasms, ANCBlock *block);
ANCMethodNameItem *anc_create_method_name_item(NSString *name, ANCTypeSpecifier *typeSpecifier, NSString *paramName);
ANCMethodDefinition *anc_create_method_definition(ANCExpression *annotaionIfConditionExpr, BOOL classMethod, ANCTypeSpecifier *returnTypeSpecifier, NSArray<ANCMethodNameItem *> *items, ANCBlock *block);
ANCPropertyDefinition *anc_create_property_definition(ANCExpression *annotaionIfConditionExpr, ANCPropertyModifier modifier, ANCTypeSpecifier *typeSpecifier, NSString *name);
void anc_add_class_definition(ANCClassDefinition *classDefinition);
void anc_add_struct_declare(ANCStructDeclare *structDeclare);
void anc_add_statement(ANCStatement *statement);




ANCInterpreter *anc_get_current_compile_util(void);
void anc_set_current_compile_util(ANCInterpreter *interpreter);




#endif /* ananasc_h */
