//
//  ananasc.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/1.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#ifndef ananasc_h
#define ananasc_h
#import "nac_ast.h"

/*create.m*/
void anc_open_string_literal_buf(void);
void anc_append_string_literal(int letter);
NSMutableString *anc_end_string_literal(void);
NSString *anc_create_identifier(char *str);
NACExpression *anc_create_expression(NACExpressionKind kind);
NACStatement *anc_create_statement(NACStatementKind kind);
NACStructDeclare *nac_create_definition(NSString *structName ,NSString *typeEncodingKey, NSString *typeEncodingValue, NSString *keysKey, NSArray<NSString *> *keysValue);

#endif /* ananasc_h */
