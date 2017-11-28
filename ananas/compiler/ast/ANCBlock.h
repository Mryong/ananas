//
//  ANCBlock.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/28.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCStatement.h"

typedef NS_ENUM(NSInteger, ANCBlockKind) {
	ANCBlockKindStatement,
	ANCBlockKindeFunction,
	ANCBlockKindBock
	
};


@interface ANCBlock: NSObject
@property (assign, nonatomic) ANCBlockKind kind;
@property (strong, nonatomic) NSArray<ANCStatement *> *statementList;
@property (weak, nonatomic) ANCBlock *outBlock;
@property (weak, nonatomic) ANCStatement *statement;
@property (weak, nonatomic) ANCFunctionDefinition *function;
@property (weak, nonatomic) ANCBlockExpression *blockExpr;

@end
