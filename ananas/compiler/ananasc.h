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
#import <CoreFoundation/CoreFoundation.h>



/*create.m*/
void anc_open_string_literal_buf(void);
void anc_append_string_literal(int letter);
const char* anc_end_string_literal(void);
NSString *anc_create_identifier(char *str);
ANCDicEntry *anc_create_dic_entry(ANCExpression *keyExpr, ANCExpression *valueExpr);
ANCExpression *anc_create_expression(ANCExpressionKind kind);
ANCStructDeclare *anc_create_struct_declare(NSString *structName, NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue);
ANCTypeSpecifier *anc_create_type_specifier(ANCExpressionTypeKind kind, NSString *identifier, NSString *typeEncoding);
ANCTypeSpecifier *anc_create_block_type_specifier(ANCTypeSpecifier *returnTypeSpecifier,NSArray<ANCTypeSpecifier *> *paramsTypeSpecifier);
ANCParameter *anc_create_parameter(ANCTypeSpecifier *type, NSString *name);
ANCDeclaration *anc_create_declaration(ANCTypeSpecifier *type, NSString *name, ANCExpression *initializer);
ANCDeclarationStatement *anc_create_declaration_statement(ANCDeclaration *declaration);
ANCExpressionStatement *anc_create_expression_statement(ANCExpression *expr);
ANCElseIf *anc_create_else_if(ANCExpression *condition, ANCBlock *thenBlock);
ANCIfStatement *anc_create_if_statement(ANCExpression *condition,ANCBlock *thenBlock,NSArray<ANCElseIf *> *elseIfList,ANCBlock *elseBlocl);
ANCCase *anc_create_case(ANCExpression *expr, ANCBlock *block);
ANCSwitchStatement *anc_create_switch_statement(ANCExpression *expr, NSArray<ANCCase *> *caseList, ANCBlock *defaultBlock);
ANCForStatement *anc_create_for_statement(NSString *label, ANCExpression *initializerExpr, ANCDeclaration *declaration,
										  ANCExpression *condition, ANCExpression *post, ANCBlock *block);
ANCForEachStatement *anc_create_for_each_statement(NSString *label, ANCTypeSpecifier *typeSpecifier, NSString *varName, ANCExpression *arrayExpr, ANCBlock *block);
ANCWhileStatement *anc_create_while_statement(NSString *label, ANCExpression *condition, ANCBlock *block);
ANCDoWhileStatement *anc_create_do_while_statement(NSString *label, ANCBlock *block, ANCExpression *condition);
ANCContinueStatement *anc_create_continue_statement(NSString *label);
ANCBreakStatement *anc_create_break_statement(NSString *label);
ANCReturnStatement *anc_create_return_statement(ANCExpression *retValExpr);
ANCBlock *anc_create_blcok_statement(NSArray<ANCStatement *> *statementList);


ANCFunctionDefinition *anc_create_function_definition(ANCTypeSpecifier *returnTypeSpecifier,NSString *name ,NSArray<ANCParameter *> *prasms, ANCBlock *block);
ANCMethodNameItem *anc_create_method_name_item(NSString *name, ANCTypeSpecifier *typeSpecifier, NSString *paramName);
ANCMethodDefinition *anc_create_method_definition(BOOL classMethod, ANCTypeSpecifier *returnTypeSpecifier, NSArray<ANCMethodNameItem *> *items, ANCBlock *block);
ANCPropertyDefinition *anc_create_property_definition(ANCPropertyModifier modifier, ANCTypeSpecifier *typeSpecifier, NSString *name);
ANCClassDefinition *anc_create_class_definition(NSString *name, NSString *superNmae, NSArray<NSString *> *protocolNames,
												NSArray<ANCMemberDefinition *> *members);










#endif /* ananasc_h */
