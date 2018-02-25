//
//  ANCFunctionDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCTypeSpecifier.h"
#import "ANCExpression.h"
#import "ANCStatement.h"
@class ANCBlock;
@class ANCMethodDefinition;

@interface ANCParameter:NSObject
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger lineNumber;
@end

typedef NS_ENUM(NSUInteger,ANCFunctionDefinitionKind) {
	ANCFunctionDefinitionKindMethod,
	ANCFunctionDefinitionKindBlock,
	ANCFunctionDefinitionKindFunction
};

@interface ANCFunctionDefinition: NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (strong, nonatomic) ANCTypeSpecifier *returnTypeSpecifier;
@property (assign, nonatomic) ANCFunctionDefinitionKind kind;
@property (copy, nonatomic) NSString *name;//or selecor
@property (strong, nonatomic) NSArray<ANCParameter *> *params;
@property (strong, nonatomic) ANCBlock *block;


@end
