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
ANEValue *ane_eval_expression(id _self,ANCInterpreter *inter, ANEScopeChain *scope,ANCExpression *expr);
void ane_interpret(ANCInterpreter *inter);

#endif /* execute_h */
