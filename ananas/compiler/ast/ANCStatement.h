//
//  ANCStatement.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCExpression.h"

typedef NS_ENUM(NSInteger, ANCStatementKind) {
	ANCStatementKindExpression = 1,
	ANCStatementKindDeclaration,
	ANCStatementKindIf,
	ANCStatementKindSwitch,
	ANCStatementKindFor,
	ANCStatementKindForEach,
	ANCStatementKindWhile,
	ANCStatementKindDoWhile,
	ANCStatementKindBreak,
	ANCStatementKindContinue,
	ANCStatementKindReturn
};

@interface ANCStatement : NSObject
@property (assign, nonatomic) ANCStatementKind kind;
@end

@interface ANCBlock: NSObject // ANCBlockStatement is not a ANCStatement

@property (strong, nonatomic) NSMutableArray<ANCBlock *> *statements;

@end

@interface ANCExpressionStatement: ANCStatement

@property (strong, nonatomic) ANCExpression *expr;

@end

@interface ANCDeclarationStatement: ANCStatement
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANCExpression *initializer;
@end


@interface ANCElseIf: ANCStatement

@property (strong, nonatomic) ANCExpression *condition;
@property (strong, nonatomic) ANCBlock *thenBlock;

@end

@interface ANCIfStatement: ANCStatement

@property (strong, nonatomic) ANCExpression *condition;
@property (strong, nonatomic) ANCBlock *thenBlock;
@property (strong, nonatomic) ANCBlock *elseBlocl;
@property (strong, nonatomic) NSMutableArray<ANCElseIf *> *elseIfList;

@end


@interface ANCCase: ANCStatement
@property (strong, nonatomic) ANCExpression *expr;
@property (strong, nonatomic) ANCBlock *block;
@end

@interface ANCSwitchStatement: ANCStatement
@property (strong, nonatomic) ANCExpression *expr;
@property (strong, nonatomic) NSMutableArray<ANCCase *> *caseList;
@property (strong, nonatomic) ANCBlock *block;
@end

@interface ANCForStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) ANCExpression *initializerExpr;
@property (assign, nonatomic) ANCDeclarationStatement *declaration;
@property (strong, nonatomic) ANCExpression *condition;
@property (strong, nonatomic) ANCExpression *post;
@property (strong, nonatomic) ANCBlock *block;
@end

@interface ANCForEachStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *varName;
@property (strong, nonatomic) ANCExpression *arrayExpr;
@property (strong, nonatomic) ANCBlock *block;
@end

@interface ANCWhileStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) ANCExpression *condition;
@property (strong, nonatomic) ANCBlock *block;
@end


@interface ANCDoWhileStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) ANCBlock *block;
@property (strong, nonatomic) ANCExpression *condition;
@end

@interface ANCContinueStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@end


@interface ANCBreakStatement: ANCStatement
@property (copy, nonatomic) NSString *label;
@end


@interface ANCReturnStatement: ANCStatement
@property (strong, nonatomic) ANCExpression *retValExpr;
@end














