//
//  execute.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#ifndef execute_h
#define execute_h

#import "ANEEnvironment.h"


/* eval.m */
BOOL ananas_equal_value(NSUInteger lineNumber,ANEValue *value1, ANEValue *value2);
ANEValue *ane_eval_expression(id _self,ANCInterpreter *inter, ANEScopeChain *scope,ANCExpression *expr);
void ane_interpret(ANCInterpreter *inter);
void ananas_assign_value_to_identifer_expr(id _self, ANCInterpreter *inter, ANEScopeChain *scope, ANCIdentifierExpression *identiferExpr,ANEValue *operValue);
/*execute.m*/
ANEStatementResult *ane_execute_statement_list(id _self, ANCInterpreter *inter, ANEScopeChain *scope, NSArray<ANCStatement *> *statementList);
#endif /* execute_h */
