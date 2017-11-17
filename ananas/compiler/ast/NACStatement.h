//
//  NACStatement.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NACExpression.h"

typedef NS_ENUM(NSInteger, NACStatementKind) {
	NACStatementKindExpression = 1,
	NACStatementKindDeclaration,
	NACStatementKindIf,
	NACStatementKindSwitch,
	NACStatementKindFor,
	NACStatementKindForEach,
	NACStatementKindWhile,
	NACStatementKindDoWhile,
	NACStatementKindBreak,
	NACStatementKindContinue,
	NACStatementKindReturn
};

@interface NACStatement : NSObject
@property (assign, nonatomic) NACStatementKind kind;
@end

@interface NACBlock: NSObject // NACBlockStatement is not a NACStatement

@property (strong, nonatomic) NSMutableArray<NACBlock *> *statements;

@end

@interface NACExpressionStatement: NACStatement

@property (strong, nonatomic) NACExpression *expr;

@end

@interface NACDeclarationStatement: NACStatement
@property (strong, nonatomic) NACTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NACExpression *initializer;
@end


@interface NACElseIf: NACStatement

@property (strong, nonatomic) NACExpression *condition;
@property (strong, nonatomic) NACBlock *thenBlock;

@end

@interface NACIfStatement: NACStatement

@property (strong, nonatomic) NACExpression *condition;
@property (strong, nonatomic) NACBlock *thenBlock;
@property (strong, nonatomic) NACBlock *elseBlocl;
@property (strong, nonatomic) NSMutableArray<NACElseIf *> *elseIfList;

@end


@interface NACCase: NACStatement
@property (strong, nonatomic) NACExpression *expr;
@property (strong, nonatomic) NACBlock *block;
@end

@interface NACSwitchStatement: NACStatement
@property (strong, nonatomic) NACExpression *expr;
@property (strong, nonatomic) NSMutableArray<NACCase *> *caseList;
@property (strong, nonatomic) NACBlock *block;
@end

@interface NACForStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) NACExpression *initializerExpr;
@property (assign, nonatomic) NACDeclarationStatement *declaration;
@property (strong, nonatomic) NACExpression *condition;
@property (strong, nonatomic) NACExpression *post;
@property (strong, nonatomic) NACBlock *block;
@end

@interface NACForEachStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) NACTypeSpecifier *type;
@property (copy, nonatomic) NSString *varName;
@property (strong, nonatomic) NACExpression *arrayExpr;
@property (strong, nonatomic) NACBlock *block;
@end

@interface NACWhileStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) NACExpression *condition;
@property (strong, nonatomic) NACBlock *block;
@end


@interface NACDoWhileStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) NACBlock *block;
@property (strong, nonatomic) NACExpression *condition;
@end

@interface NACContinueStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@end


@interface NACBreakStatement: NACStatement
@property (copy, nonatomic) NSString *label;
@end


@interface NACReturnStatement: NACStatement
@property (strong, nonatomic) NACExpression *retValExpr;
@end














