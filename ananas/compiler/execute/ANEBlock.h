//
//  ANEBlock.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "anc_ast.h"
#import "ANCInterpreter.h"

@interface ANEBlock : NSObject
@property (strong, nonatomic) ANEScopeChain *scope;
@property (strong, nonatomic) ANCFunctionDefinition *func;
@property (strong, nonatomic) ANCInterpreter *inter;
@property (assign, nonatomic) const char *typeEncoding;

@end
