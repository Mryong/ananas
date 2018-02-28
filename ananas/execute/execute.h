//
//  execute.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#ifndef execute_h
#define execute_h
#import "runenv.h"

/*built-in.m*/
void mango_add_built_in(MANInterpreter *inter);
/* eval.m */
BOOL mango_equal_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2);
ANEValue *ane_eval_expression(MANInterpreter *inter, MANScopeChain *scope,MANExpression *expr);
void ane_interpret(MANInterpreter *inter);
void mango_assign_value_to_identifer_expr(MANInterpreter *inter, MANScopeChain *scope, NSString *identifer,ANEValue *operValue);
/*execute.m*/
MANStatementResult *ane_execute_statement_list(MANInterpreter *inter, MANScopeChain *scope, NSArray<MANStatement *> *statementList);
ANEValue * mango_call_mango_function(MANInterpreter *inter, MANScopeChain *scope, MANFunctionDefinition *func, NSArray<ANEValue *> *args);
#endif /* execute_h */
