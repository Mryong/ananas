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



/*create.m*/
void anc_open_string_literal_buf(void);
void anc_append_string_literal(int letter);
NSMutableString *anc_end_string_literal(void);
NSString *anc_create_identifier(char *str);
ANCExpression *anc_create_expression(ANCExpressionKind kind);
ANCStatement *anc_create_statement(ANCStatementKind kind);
ANCStructDeclare *anc_create_struct_declare(NSString *structName, NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue);

#endif /* ananasc_h */
