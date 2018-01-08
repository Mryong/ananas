//
//  ANCExpression.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANCTypeSpecifier.h"
@class ANCFunctionDefinition;
@class ANCBlock;


typedef NS_ENUM(NSInteger, ANCExpressionKind) {
	ANC_BOOLEAN_EXPRESSION = 1,
	ANC_INT_EXPRESSION,
	ANC_U_INT_EXPRESSION,
	ANC_FLOAT_EXPRESSION,
	ANC_DOUBLE_EXPRESSION,
	ANC_STRING_EXPRESSION,
	ANC_SELECTOR_EXPRESSION,
	ANC_BLOCK_EXPRESSION,
	ANC_IDENTIFIER_EXPRESSION,
	ANC_TERNARY_EXPRESSION,
	ANC_ASSIGN_EXPRESSION,
	ANC_PLUS_EXPRESSION,
	ANC_MINUS_EXPRESSION,
	ANC_MUL_EXPRESSION,
	ANC_DIV_EXPRESSION,
	ANC_MOD_EXPRESSION,
	ANC_EQ_EXPRESSION,
	ANC_NE_EXPRESSION,
	ANC_GT_EXPRESSION,
	ANC_GE_EXPRESSION,
	ANC_LT_EXPRESSION,
	ANC_LE_EXPRESSION,
	ANC_LOGICAL_AND_EXPRESSION,
	ANC_LOGICAL_OR_EXPRESSION,
	ANC_LOGICAL_NOT_EXPRESSION,
	NSC_NEGATIVE_EXPRESSION,
	ANC_FUNCTION_CALL_EXPRESSION,
	ANC_MEMBER_EXPRESSION,
	ANC_NIL_EXPRESSION,
	ANC_SELF_EXPRESSION,
	ANC_SUPER_EXPRESSION,
	ANC_ARRAY_LITERAL_EXPRESSION,
	ANC_DIC_LITERAL_EXPRESSION,
	ANC_STRUCT_LITERAL_EXPRESSION,
	ANC_INDEX_EXPRESSION,
	ANC_INCREMENT_EXPRESSION,
	ANC_DECREMENT_EXPRESSION,
	ANC_AT_EXPRESSION
};




@interface ANCExpression : NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (assign, nonatomic) ANCExpressionKind expressionKind;
@property (strong, nonatomic) ANCTypeSpecifier *typeSpecifier;
@property (assign, nonatomic) BOOL bool_value;
@property (assign, nonatomic) NSInteger integer_value;
@property (assign, nonatomic) NSUInteger uinteger_value;
@property (assign, nonatomic) CGFloat float_value;
@property (assign, nonatomic) double double_value;
@property (assign, nonatomic) const char *utf8_string_value;
@property (copy, nonatomic) NSString *selectorName;
@end

@interface ANCIdentifierExpression: ANCExpression
@property (copy, nonatomic) NSString *identifier;
@end


typedef NS_ENUM(NSInteger, ANCAssignKind) {
	ANC_NORMAL_ASSIGN,
	ANC_MINUS_ASSIGN,
	ANC_PLUS_ASSIGN,
	ANC_MUL_ASSIGN,
	ANC_DIV_ASSIGN,
	ANC_MOD_ASSIGN
};


@interface ANCAssignExpression: ANCExpression
@property (assign, nonatomic) ANCAssignKind assignKind;
@property (strong, nonatomic) ANCExpression *left;
@property (strong, nonatomic) ANCExpression *right;
@end

@interface ANCBinaryExpression: ANCExpression

@property (strong, nonatomic) ANCExpression *left;
@property (strong, nonatomic) ANCExpression *right;

@end


@interface ANCTernaryExpression: ANCExpression
@property (strong, nonatomic) ANCExpression *condition;
@property (strong, nonatomic) ANCExpression *trueExpr;
@property (strong, nonatomic) ANCExpression *falseExpr;

@end

@interface ANCUnaryExpression: ANCExpression

@property (strong, nonatomic) ANCExpression *expr;

@end

@interface ANCMemberExpression: ANCExpression

@property (strong, nonatomic) ANCExpression *expr;
@property (copy, nonatomic) NSString *memberName;

@end


@interface ANCFunctonCallExpression: ANCExpression

@property (strong, nonatomic) ANCExpression *expr;
@property (strong, nonatomic) NSArray<ANCExpression *> *args;

@end


@interface ANCIndexExpression: ANCExpression

@property (strong, nonatomic) ANCExpression *arrayExpression;
@property (strong, nonatomic) ANCExpression *indexExpression;

@end




@interface ANCStructpression: ANCExpression

@property (strong, nonatomic) NSMutableArray<ANCExpression *> *keyExpressions;
@property (strong, nonatomic) NSMutableArray<ANCExpression *> *valueExpressions;

@end



@interface ANCDicEntry: NSObject
@property (strong, nonatomic) ANCExpression *keyExpr;
@property (strong, nonatomic) ANCExpression *valueExpr;

@end

@interface ANCDictionaryExpression: ANCExpression

@property (strong, nonatomic) NSArray<ANCDicEntry *> *entriesExpr;

@end


@interface ANCArrayExpression: ANCExpression

@property (strong, nonatomic) NSArray<ANCExpression *> *itemExpressions;

@end


@interface ANCBlockExpression: ANCExpression
@property (strong, nonatomic) ANCFunctionDefinition *func;

@end






















