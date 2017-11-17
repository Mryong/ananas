//
//  NACExpression.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NACTypeSpecifier.h"

typedef NS_ENUM(NSInteger, NACExpressionKind) {
	NAC_BOOLEAN_EXPRESSION = 1,
	NAC_INT_EXPRESSION,
	NAC_U_INT_EXPRESSION,
	NAC_FLOAT_EXPRESSION,
	NAC_DOUBLE_EXPRESSION,
	NAC_STRING_EXPRESSION,
	NAC_IDENTIFIER_EXPRESSION,
	NAC_ASSIGN_EXPRESSION,
	NAC_PLUS_EXPRESSION,
	NAC_MINUS_EXPRESSION,
	NAC_MUL_EXPRESSION,
	NAC_DIV_EXPRESSION,
	NAC_MOD_EXPRESSION,
	NAC_EQ_EXPRESSION,
	NAC_NE_EXPRESSION,
	NAC_GT_EXPRESSION,
	NAC_GE_EXPRESSION,
	NAC_LT_EXPRESSION,
	NAC_LE_EXPRESSION,
	NAC_LOGICAL_AND_EXPRESSION,
	NAC_LOGICAL_OR_EXPRESSION,
	NAC_LOGICAL_NOT_EXPRESSION,
	NAC_FUNCTION_CALL_EXPRESSION,
	NAC_MEMBER_EXPRESSION,
	NAC_NIL_EXPRESSION,
	NAC_SELF_EXPRESSION,
	NAC_SUPER_EXPRESSION,
	NAC_ARRAY_LITERAL_EXPRESSION,
	NAC_DIC_LITERAL_EXPRESSION,
	NAC_STRUCT_LITERAL_EXPRESSION,
	NAC_INDEX_EXPRESSION,
	NSC_NEGATIVE_EXPRESSION,
	NAC_INCREMENT_EXPRESSION,
	NAC_DECREMENT_EXPRESSION
};





@interface NACExpression : NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (assign, nonatomic) NACExpressionKind expressionKind;
@property (strong, nonatomic) NACTypeSpecifier *typeSpecifier;
@property (assign, nonatomic) BOOL bool_value;
@property (assign, nonatomic) NSInteger integer_value;
@property (assign, nonatomic) NSUInteger uinteger_value;
@property (assign, nonatomic) CGFloat float_value;
@property (assign, nonatomic) double double_value;
@property (copy, nonatomic) NSString *string_value;
@end

@interface NACIdentifierExpression: NACExpression
@property (copy, nonatomic) NSString *identifier;
@end


typedef NS_ENUM(NSInteger, NACAssignKind) {
	NAC_NORMAL_ASSIGN,
	NAC_MINUS_ASSIGN,
	NAC_PLUS_ASSIGN,
	NAC_MUL_ASSIGN,
	NAC_DIV_ASSIGN,
	NAC_MOD_ASSIGN
};


@interface NACAssignExpression: NACExpression
@property (assign, nonatomic) NACAssignKind assignKind;
@property (strong, nonatomic) NACExpression *left;
@property (strong, nonatomic) NACExpression *right;
@end

@interface NACBinaryExpression: NACExpression

@property (strong, nonatomic) NACExpression *left;
@property (strong, nonatomic) NACExpression *right;

@end


@interface NACUnaryExpression: NACExpression

@property (strong, nonatomic) NACExpression *expr;

@end

@interface NACMemberExpression: NACExpression

@property (strong, nonatomic) NACExpression *expr;
@property (copy, nonatomic) NSString *memberName;

@end


@interface NACFunctonCallExpression: NACExpression

@property (strong, nonatomic) NACExpression *expr;
@property (strong, nonatomic) NSMutableArray<NACExpression *> *args;

@end


@interface NACIndexExpression: NACExpression

@property (strong, nonatomic) NACExpression *arrayExpression;
@property (strong, nonatomic) NACExpression *indexExpression;

@end




@interface NACStructpression: NACExpression

@property (strong, nonatomic) NSMutableArray<NACExpression *> *keyExpressions;
@property (strong, nonatomic) NSMutableArray<NACExpression *> *valueExpressions;

@end

@interface NACDictionaryExpression: NACExpression

@property (strong, nonatomic) NSMutableArray<NACExpression *> *keyExpressions;
@property (strong, nonatomic) NSMutableArray<NACExpression *> *valueExpressions;

@end


@interface NACArrayExpression: NACExpression

@property (strong, nonatomic) NSMutableArray<NACExpression *> *itemExpressions;

@end






















