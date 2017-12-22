//
//  ANC.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/23.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#ifndef ANC_h
#define ANC_h

#import "anc_ast.h"

Interpreter *anc_get_current_compile_util(void);
void anc_set_current_compile_util(Interpreter *interpreter);

#endif /* ANC_h */
