//
//  NSCTypeSpecifier.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, ANCTypeSpecifierKind) {
	ANC_TYPE_VOID,
	ANC_TYPE_BOOL,
	ANC_TYPE_CHAR,
	ANC_TYPE_NS_U_INTEGER,
	ANC_TYPE_NS_INTEGER,
	ANC_TYPE_CG_FLOAT,
	ANC_TYPE_DOUBLE,
	ANC_TYPE_STRING,//char *
	ANC_TYPE_CLASS,
	ANC_TYPE_SEL,
	ANC_TYPE_NS_OBJECT,
	ANC_TYPE_STRUCT,
	ANC_TYPE_STRUCT_LITERAL,
	ANC_TYPE_NS_BLOCK,
	ANC_TYPE_ANANAS_BLOCK,
	ANC_TYPE_POINTER
};
@interface ANCTypeSpecifier : NSObject
@property (copy, nonatomic) NSString *identifer;
@property (assign, nonatomic) ANCTypeSpecifierKind typeKind;
@property (copy, nonatomic) NSString *typeEncoding;

@property (strong, nonatomic) ANCTypeSpecifier *returnTypeSpecifier;//for block type
@property (strong, nonatomic) NSArray<ANCTypeSpecifier *> *paramsTypeSpecifier;//for block type

@end
